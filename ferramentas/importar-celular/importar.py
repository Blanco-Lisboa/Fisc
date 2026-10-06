import argparse
import getpass
import json
import mimetypes
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request

SB_URL = "https://vvohwixeokxydmbhqklu.supabase.co"
SB_KEY = "sb_publishable_jQVklnYdEmsbVYzsp7_0Nw_ZLht78GM"
BL_URL = "https://wfqcoocfastgsfgegpcm.supabase.co"
BL_KEY = "sb_publishable_88ukR4t1KNTc73DxbF6-Pw_0CKW16Fe"

TIPOS = {0: "texto", 1: "imagem", 2: "audio", 3: "video", 4: "contato", 5: "local", 9: "documento", 13: "imagem", 20: "figurinha"}
LOTE = 400


def http(metodo, url, corpo=None, cabecalhos=None, bruto=None):
    dados = bruto if bruto is not None else (json.dumps(corpo).encode() if corpo is not None else None)
    req = urllib.request.Request(url, data=dados, method=metodo, headers=cabecalhos or {})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            texto = r.read().decode() or "{}"
            return r.status, json.loads(texto) if texto.strip().startswith(("{", "[")) else {}
    except urllib.error.HTTPError as e:
        texto = e.read().decode()
        try:
            return e.code, json.loads(texto)
        except ValueError:
            return e.code, {"erro": texto[:300]}


def login_bl(usuario):
    u = usuario.strip()
    if "@" not in u:
        cpf = "".join(ch for ch in u if ch.isdigit())
        u = cpf + "@cpf.youcontabilidade.local"
    senha = getpass.getpass("Senha da BL: ")
    st, j = http("POST", BL_URL + "/auth/v1/token?grant_type=password", {"email": u.lower(), "password": senha},
                 {"apikey": BL_KEY, "Content-Type": "application/json"})
    if st != 200:
        sys.exit("Login da BL recusado.")
    st, f = http("POST", SB_URL + "/functions/v1/fiscal-entrar", {"bl_token": j["access_token"]},
                 {"apikey": SB_KEY, "Content-Type": "application/json"})
    if st != 200 or not f.get("ok"):
        sys.exit("Sem acesso ao Fiscal: " + str(f.get("erro")))
    return f["access_token"]


def abrir_backup(arquivo, pasta_tmp):
    if arquivo.endswith(".db"):
        return arquivo
    chave = getpass.getpass("Chave de 64 digitos do backup: ").replace(" ", "").strip()
    saida = os.path.join(pasta_tmp, "msgstore.db")
    r = subprocess.run(["wadecrypt", chave, arquivo, saida], capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(saida):
        sys.exit("Nao consegui abrir o backup (chave ou arquivo errado).")
    return saida


def telefone_do_chat(db, jid_row):
    j = db.execute("select user, server from jid where _id = ?", (jid_row,)).fetchone()
    if not j:
        return None
    user, server = j
    if server == "s.whatsapp.net":
        return user
    if server == "lid":
        try:
            m = db.execute("select j.user from jid_map jm join jid j on j._id = jm.jid_row_id where jm.lid_row_id = ?",
                           (jid_row,)).fetchone()
            return m[0] if m else None
        except sqlite3.Error:
            return None
    return None


def ler_conversas(caminho_db, desde_ms):
    db = sqlite3.connect(caminho_db)
    chats = db.execute("select _id, jid_row_id from chat").fetchall()
    conversas = []
    for chat_id, jid_row in chats:
        tel = telefone_do_chat(db, jid_row)
        if not tel:
            continue
        linhas = db.execute(
            "select m._id, m.key_id, m.from_me, m.timestamp, m.message_type, m.text_data,"
            " mm.file_path, mm.mime_type, mm.file_size, mm.media_name, mm.media_caption,"
            " (select q.key_id from message_quoted q where q.message_row_id = m._id)"
            " from message m left join message_media mm on mm.message_row_id = m._id"
            " where m.chat_row_id = ? and m.timestamp >= ? order by m.timestamp", (chat_id, desde_ms)).fetchall()
        msgs = []
        for _id, key_id, de_mim, ts, tipo_n, texto, fpath, mime, tam, nome, legenda, responde in linhas:
            tipo = TIPOS.get(tipo_n)
            if not tipo or not key_id:
                continue
            msg = {"id": key_id, "de_mim": bool(de_mim), "ts_ms": int(ts), "tipo": tipo,
                   "texto": texto if tipo in ("texto", "contato", "local") else (nome or None), "responde": responde}
            if tipo not in ("texto", "contato", "local"):
                msg["legenda"] = legenda or (texto if texto else None)
                if fpath:
                    ext = os.path.splitext(fpath)[1].lstrip(".")
                    msg["midia"] = {"chave": str(_id), "arquivo": fpath, "mime": mime, "tamanho": tam,
                                    "nome": nome or os.path.basename(fpath), "ext": ext}
            msgs.append(msg)
        if msgs:
            conversas.append({"telefone": tel, "mensagens": msgs})
    db.close()
    return conversas


def achar_arquivo(raiz, relativo):
    rel = relativo.replace("\\", "/")
    for tentativa in (rel, rel.split("Media/", 1)[-1], "Media/" + rel.split("Media/", 1)[-1]):
        p = os.path.join(raiz, tentativa)
        if os.path.isfile(p):
            return p
    alvo = os.path.basename(rel)
    for pasta, _, arqs in os.walk(raiz):
        if alvo in arqs:
            return os.path.join(pasta, alvo)
    return None


def main():
    ap = argparse.ArgumentParser(description="Importa o historico do WhatsApp Business do celular para o Fiscal")
    ap.add_argument("--backup", required=True, help="msgstore.db.crypt15 (ou msgstore.db ja aberto)")
    ap.add_argument("--midias", required=True, help="pasta 'WhatsApp Business' copiada do celular")
    ap.add_argument("--numero", required=True, help="numero do Fiscal, ex.: 5511999999999")
    ap.add_argument("--usuario", required=True, help="e-mail ou CPF da BL (assistente/gerente do Fiscal)")
    ap.add_argument("--desde", default="2000-01-01", help="so mensagens a partir desta data (AAAA-MM-DD)")
    a = ap.parse_args()

    import datetime
    desde_ms = int(datetime.datetime.fromisoformat(a.desde).timestamp() * 1000)
    token = login_bl(a.usuario)
    cab = {"apikey": SB_KEY, "Authorization": "Bearer " + token, "Content-Type": "application/json"}

    pasta_tmp = tempfile.mkdtemp(prefix="fiscal-import-")
    try:
        db = abrir_backup(a.backup, pasta_tmp)
        conversas = ler_conversas(db, desde_ms)
        total = sum(len(c["mensagens"]) for c in conversas)
        print(f"Conversas: {len(conversas)} | mensagens: {total}")
        novas = repetidas = enviadas = sem_arquivo = 0
        for i, c in enumerate(conversas, 1):
            for k in range(0, len(c["mensagens"]), LOTE):
                parte = {"telefone": c["telefone"], "mensagens": c["mensagens"][k:k + LOTE]}
                por_chave = {m["midia"]["chave"]: m["midia"] for m in parte["mensagens"] if "midia" in m}
                st, r = http("POST", SB_URL + "/functions/v1/wa-importar-historico",
                             {"acao": "lote", "telefone_numero": a.numero, "conversas": [parte]}, cab)
                if st != 200 or not r.get("ok"):
                    sys.exit("Falha no envio: " + str(r.get("erro")))
                novas += r["novas"]
                repetidas += r["repetidas"]
                for e in r.get("envios", []):
                    md = por_chave.get(e["chave"])
                    local = achar_arquivo(a.midias, md["arquivo"]) if md else None
                    if not local:
                        sem_arquivo += 1
                        continue
                    mime = md.get("mime") or mimetypes.guess_type(local)[0] or "application/octet-stream"
                    with open(local, "rb") as f:
                        st2, _ = http("PUT", e["url"], bruto=f.read(), cabecalhos={"Content-Type": mime})
                    if st2 in (200, 201):
                        http("POST", SB_URL + "/functions/v1/wa-importar-historico",
                             {"acao": "midia_ok", "midia_id": e["midia_id"], "caminho": e["caminho"],
                              "tamanho": os.path.getsize(local)}, cab)
                        enviadas += 1
            print(f"[{i}/{len(conversas)}] ok")
        print(f"Pronto. Novas: {novas} | ja existiam: {repetidas} | arquivos enviados: {enviadas} | arquivos nao achados: {sem_arquivo}")
    finally:
        shutil.rmtree(pasta_tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
