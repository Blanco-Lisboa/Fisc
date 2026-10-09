import sqlite3, sys, os, json, time, base64, mimetypes, urllib.request, urllib.error, threading
from concurrent.futures import ThreadPoolExecutor, as_completed

SCR = os.path.dirname(os.path.abspath(__file__))
FONTE = os.path.join(SCR, 'wadb', 'msgstore.db')
ESTADO = os.path.join(SCR, 'wahist', 'estado.db')
BASE = 'D:/wpp fiscal/WhatsApp Business/'
EDGE = 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/wa-historico-backup'
CHAVE = open(os.path.join(SCR, 'wahist', 'chave.tmp')).read().strip()
LOG = open(os.path.join(SCR, 'wahist', 'log.txt'), 'a', encoding='utf-8')

def log(*a):
    s = time.strftime('%H:%M:%S ') + ' '.join(str(x) for x in a)
    print(s, flush=True); LOG.write(s + '\n'); LOG.flush()

def chamar(corpo, tent=6):
    dado = json.dumps(corpo, ensure_ascii=False).encode('utf-8')
    for i in range(tent):
        try:
            rq = urllib.request.Request(EDGE, data=dado, method='POST', headers={'Content-Type': 'application/json', 'x-chave-interna': CHAVE})
            with urllib.request.urlopen(rq, timeout=150) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            txt = e.read().decode('utf-8', 'replace')[:300]
            if e.code in (400, 403): raise RuntimeError(f'{e.code} {txt}')
            log('tentando de novo', e.code, txt)
        except Exception as e:
            log('tentando de novo', repr(e)[:200])
        time.sleep(3 * (i + 1))
    raise RuntimeError('edge nao respondeu')

st = sqlite3.connect(ESTADO, check_same_thread=False)
st.execute('create table if not exists lote (chave text primary key)')
st.execute('create table if not exists midia (midia_id text primary key, arquivo text, caminho text, feito int default 0)')
st.commit()
trava = threading.Lock()

TIPO = {0: 'texto', 1: 'imagem', 42: 'imagem', 2: 'audio', 3: 'video', 13: 'video', 43: 'video', 9: 'documento',
        20: 'figurinha', 4: 'contato', 14: 'contato', 5: 'local', 16: 'local', 90: 'sistema', 15: 'texto', 64: 'texto'}

def montar():
    c = sqlite3.connect(FONTE)
    c.row_factory = sqlite3.Row
    jid = {r['_id']: r for r in c.execute('select _id, user, server from jid')}
    mapa = {r[0]: r[1] for r in c.execute('select lid_row_id, jid_row_id from jid_map')}
    def fone(jrow):
        j = jid.get(jrow)
        if not j: return None
        if j['server'] == 'lid':
            p = mapa.get(jrow)
            if p and jid.get(p) and jid[p]['server'] == 's.whatsapp.net': return jid[p]['user']
            return None
        if j['server'] == 's.whatsapp.net': return j['user']
        return None
    def autor(jrow):
        f = fone(jrow)
        if f: return f
        j = jid.get(jrow)
        return ('lid:' + j['user']) if j else None

    quoted = {r[0]: r[1] for r in c.execute('select message_row_id, key_id from message_quoted')}
    fwd = {r[0] for r in c.execute('select message_row_id from message_forwarded')}
    edit = {r[0]: r[1] for r in c.execute('select message_row_id, edited_timestamp from message_edit_info')}
    revog = {r[0]: r[1] for r in c.execute('select message_row_id, revoke_timestamp from message_revoked')}
    reac = {}
    for r in c.execute('select a.parent_message_row_id p, a.from_me f, x.reaction r from message_add_on a join message_add_on_reaction x on x.message_add_on_row_id = a._id order by a.timestamp'):
        reac[(r['p'], r['f'])] = r['r'] or None
    vc = {}
    for r in c.execute('select message_row_id, vcard from message_vcard order by _id'):
        vc.setdefault(r[0], []).append(r[1])
    loc = {r['message_row_id']: dict(r) for r in c.execute('select message_row_id, latitude, longitude, place_name, place_address from message_location')}
    calls = {}
    for r in c.execute('select mc.message_row_id, cl.video_call, cl.duration, cl.from_me, cl.call_result from message_call_log mc join call_log cl on cl._id = mc.call_log_row_id'):
        calls[r[0]] = r
    med = {r['message_row_id']: r for r in c.execute('select message_row_id, file_path, file_size, mime_type, media_name, media_duration, file_hash from message_media')}
    membros = {}
    for r in c.execute('select group_jid_row_id g, user_jid_row_id u, rank, add_timestamp t from group_participant_user'):
        f = fone(r['u'])
        if f: membros.setdefault(r['g'], []).append({'telefone': f, 'admin': (r['rank'] or 0) > 0, 'entrou_ms': r['t'] or None})

    pulos = {}
    chats = []
    for ch in c.execute('select _id, jid_row_id, subject, created_timestamp from chat'):
        j = jid.get(ch['jid_row_id'])
        if not j: continue
        if j['server'] == 'g.us':
            conv = {'e_grupo': True, 'telefone': j['user'], 'nome': ch['subject'], 'criado_ms': ch['created_timestamp'] or None,
                    'membros': membros.get(ch['jid_row_id'], [])}
        elif j['server'] in ('s.whatsapp.net', 'lid'):
            f = fone(ch['jid_row_id'])
            if not f:
                pulos['chat_sem_numero'] = pulos.get('chat_sem_numero', 0) + 1
                continue
            conv = {'e_grupo': False, 'telefone': f, 'nome': None}
        else:
            continue
        msgs = []
        for m in c.execute('select * from message where chat_row_id = ? and timestamp > 0 order by timestamp, _id', (ch['_id'],)):
            t = m['message_type']
            txt = m['text_data']
            tipo = TIPO.get(t)
            if tipo is None:
                if txt: tipo = 'texto'
                else:
                    pulos[f'tipo_{t}'] = pulos.get(f'tipo_{t}', 0) + 1
                    continue
            if t == 7 and not txt:
                pulos['sistema_sem_texto'] = pulos.get('sistema_sem_texto', 0) + 1
                continue
            if not m['key_id']: continue
            d = {'id': m['key_id'], 'de_mim': bool(m['from_me']), 'tipo': tipo, 'ts_ms': m['timestamp']}
            dados = {'tipo_wa': t}
            if m['from_me']:
                d['status'] = 'lida' if m['status'] in (8, 13) else 'entregue' if m['status'] == 5 else 'enviada'
            if conv['e_grupo'] and not m['from_me'] and m['sender_jid_row_id']:
                d['autor'] = autor(m['sender_jid_row_id'])
            mm = med.get(m['_id'])
            if tipo in ('imagem', 'audio', 'video', 'documento', 'figurinha'):
                d['legenda'] = txt
                if mm is not None:
                    fp = mm['file_path']
                    tem = bool(fp) and os.path.isfile(os.path.join(BASE, fp))
                    ext = os.path.splitext(fp)[1].lstrip('.').lower() if fp else ''
                    if not ext and mm['mime_type']: ext = (mimetypes.guess_extension(mm['mime_type']) or '').lstrip('.')
                    sha = None
                    if mm['file_hash']:
                        try: sha = base64.b64decode(mm['file_hash']).hex()
                        except Exception: sha = None
                    d['midia'] = {'chave': fp, 'tem_arquivo': tem, 'mime': mm['mime_type'], 'nome': mm['media_name'] or (os.path.basename(fp) if fp else None),
                                  'tamanho': (os.path.getsize(os.path.join(BASE, fp)) if tem else mm['file_size']) or None,
                                  'duracao': mm['media_duration'] or None, 'sha256': sha, 'ext': ext[:8]}
            elif tipo == 'contato':
                cards = vc.get(m['_id'], [])
                nomes = []
                for v in cards:
                    for ln in (v or '').splitlines():
                        if ln.upper().startswith('FN:'): nomes.append(ln[3:].strip())
                d['texto'] = txt or ', '.join(nomes) or None
                dados['vcards'] = cards
            elif tipo == 'local':
                l = loc.get(m['_id'], {})
                d['texto'] = txt or l.get('place_name') or l.get('place_address')
                dados.update({'lat': l.get('latitude'), 'lng': l.get('longitude'), 'endereco': l.get('place_address')})
            elif t == 90:
                cl = calls.get(m['_id'])
                if cl:
                    dur = cl['duration'] or 0
                    tx = 'Ligação de vídeo' if cl['video_call'] else 'Ligação de voz'
                    tx += f' · {dur // 60}:{dur % 60:02d}' if dur > 0 else (' · não atendida')
                    d['texto'] = tx
                    dados.update({'ligacao': {'video': bool(cl['video_call']), 'duracao_s': dur, 'resultado': cl['call_result']}})
                else:
                    d['texto'] = 'Ligação'
            else:
                d['texto'] = txt
            if t in (15, 64) or m['_id'] in revog:
                d['apagada_ms'] = revog.get(m['_id']) or m['timestamp']
            if m['_id'] in quoted: d['responde'] = quoted[m['_id']]
            if m['_id'] in fwd: d['encaminhada'] = True
            if m['_id'] in edit: d['editada_ms'] = edit[m['_id']]
            if m['starred']: d['favorita'] = True
            r1 = reac.get((m['_id'], 0)); r2 = reac.get((m['_id'], 1))
            if r1: d['reacao'] = r1
            if r2: d['reacao_nossa'] = r2
            d['dados'] = {k: v for k, v in dados.items() if v is not None}
            msgs.append(d)
        if msgs or conv['e_grupo']:
            conv['_n'] = ch['_id']
            conv['mensagens'] = msgs
            chats.append(conv)
    return chats, pulos

def fase_mensagens(chats, tam=400):
    feitos = {r[0] for r in st.execute('select chave from lote')}
    tot_n = tot_r = 0
    for i, conv in enumerate(chats):
        msgs = conv.pop('mensagens'); nid = conv.pop('_n')
        partes = [msgs[k:k + tam] for k in range(0, len(msgs), tam)] or [[]]
        for k, parte in enumerate(partes):
            ch = f'{nid}:{k}'
            if ch in feitos: continue
            corpo = dict(conv); corpo['mensagens'] = parte
            r = chamar({'acao': 'lote', 'conversas': [corpo]})
            if not r.get('ok'): raise RuntimeError(r)
            tot_n += r['novas']; tot_r += r['repetidas']
            with trava:
                for md in r.get('midias', []):
                    st.execute('insert or ignore into midia (midia_id, arquivo, caminho) values (?,?,?)', (md['midia_id'], md['chave'], md['caminho']))
                st.execute('insert into lote values (?)', (ch,))
                st.commit()
        if i % 25 == 0: log(f'conversa {i + 1}/{len(chats)} novas={tot_n} repetidas={tot_r}')
    log(f'mensagens fim novas={tot_n} repetidas={tot_r}')

def subir(url, arquivo, mime):
    tam = os.path.getsize(arquivo)
    for i in range(4):
        try:
            with open(arquivo, 'rb') as f:
                rq = urllib.request.Request(url, data=f, method='PUT', headers={'Content-Type': mime or 'application/octet-stream', 'Content-Length': str(tam), 'x-upsert': 'true'})
                with urllib.request.urlopen(rq, timeout=900) as r:
                    r.read()
            return tam
        except urllib.error.HTTPError as e:
            txt = e.read().decode('utf-8', 'replace')[:300]
            if e.code in (400, 413): raise RuntimeError(f'{e.code} {txt}')
            err = f'{e.code} {txt}'
        except Exception as e:
            err = repr(e)[:200]
        time.sleep(5 * (i + 1))
    raise RuntimeError(err)

def fase_midias(paralelo=8):
    pend = st.execute('select midia_id, arquivo, caminho from midia where feito = 0 order by rowid').fetchall()
    log('midias pendentes', len(pend))
    feitos_arq = {r[0]: r[1] for r in st.execute('select arquivo, caminho from midia where feito = 1')}
    unicos = {}
    for mid, arq, cam in pend:
        if arq in feitos_arq: continue
        unicos.setdefault(arq, (mid, cam))
    fila_ok = []
    def descarregar(forcar=False):
        if fila_ok and (forcar or len(fila_ok) >= 100):
            itens = fila_ok[:]; fila_ok.clear()
            chamar({'acao': 'midia_ok', 'itens': itens})
            with trava:
                st.executemany('update midia set feito = 1 where midia_id = ?', [(x['midia_id'],) for x in itens]); st.commit()
    lst = list(unicos.items())
    subidos = 0; bytes_ = 0; t0 = time.time()
    for b in range(0, len(lst), 50):
        bloco = lst[b:b + 50]
        u = chamar({'acao': 'urls', 'caminhos': [cam for _, (_, cam) in bloco]})
        with ThreadPoolExecutor(paralelo) as ex:
            fut = {}
            for arq, (mid, cam) in bloco:
                url = u['urls'].get(cam)
                if not url:
                    fut[ex.submit(lambda e=u['falhas'].get(cam): (_ for _ in ()).throw(RuntimeError(e or 'sem url')))] = (arq, mid, cam)
                    continue
                mime = mimetypes.guess_type(arq)[0]
                fut[ex.submit(subir, url + '', os.path.join(BASE, arq), mime)] = (arq, mid, cam)
            for f in as_completed(fut):
                arq, mid, cam = fut[f]
                try:
                    tam = f.result()
                    fila_ok.append({'midia_id': mid, 'caminho': cam, 'tamanho': tam})
                    feitos_arq[arq] = cam; subidos += 1; bytes_ += tam
                except Exception as e:
                    log('falhou', arq, str(e)[:200])
                    try: chamar({'acao': 'midia_falhou', 'midia_id': mid, 'erro': str(e)[:400]})
                    except Exception: pass
                    with trava:
                        st.execute('update midia set feito = 2 where midia_id = ?', (mid,)); st.commit()
        descarregar()
        el = time.time() - t0
        log(f'arquivos {subidos}/{len(lst)} {bytes_ / 1e9:.2f}GB {bytes_ / 1e6 / max(el, 1):.1f}MB/s')
    descarregar(True)
    resto = st.execute('select midia_id, arquivo from midia where feito = 0').fetchall()
    for mid, arq in resto:
        if arq in feitos_arq: fila_ok.append({'midia_id': mid, 'caminho': feitos_arq[arq], 'tamanho': None})
        descarregar()
    descarregar(True)
    log('midias fim', st.execute('select feito, count(*) from midia group by 1').fetchall())

if __name__ == '__main__':
    fase = sys.argv[1]
    if fase in ('teste', 'mensagens'):
        chats, pulos = montar()
        n = sum(len(c['mensagens']) for c in chats)
        log(f'conversas={len(chats)} grupos={sum(1 for c in chats if c["e_grupo"])} mensagens={n} pulados={pulos}')
        if fase == 'teste':
            alvo = [c for c in chats if not c['e_grupo'] and len(c['mensagens']) > 20][:1]
            alvo[0]['mensagens'] = alvo[0]['mensagens'][:30]
            fase_mensagens(alvo, tam=30)
        else:
            fase_mensagens(chats)
    elif fase == 'midias':
        fase_midias(int(sys.argv[2]) if len(sys.argv) > 2 else 8)
    elif fase == 'finalizar':
        log(chamar({'acao': 'finalizar'}))
