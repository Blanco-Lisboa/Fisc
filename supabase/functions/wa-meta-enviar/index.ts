import { createClient } from "npm:@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const sb = createClient(URL_SB, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
};

const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...CORS, "Content-Type": "application/json" } });

let cache: { token?: string; base?: string; ate: number } = { ate: 0 };

// segredo
async function credenciais() {
  if (cache.token && cache.base && cache.ate > Date.now()) return cache as { token: string; base: string };
  const [t, c] = await Promise.all([
    sb.rpc("fiscal_meta_segredo", { p_slot: "token" }),
    sb.rpc("fiscal_meta_config"),
  ]);
  if (t.error) throw new Error(`token: ${t.error.message}`);
  if (c.error) throw new Error(`config: ${c.error.message}`);
  const raiz = (c.data.base_url || "https://graph.facebook.com").replace(/\/+$/, "");
  const base = /\/v\d+(\.\d+)?$/.test(raiz) ? raiz : `${raiz}/${c.data.versao}`;
  cache = { token: t.data as string, base, ate: Date.now() + 50 * 60 * 1000 };
  return cache as { token: string; base: string };
}

const TIPO_META: Record<string, string> = { imagem: "image", audio: "audio", video: "video", documento: "document" };

type Pedido = {
  conversa_id: string;
  id_local: string;
  tipo: "texto" | "template" | "imagem" | "audio" | "video" | "documento" | "local" | "contato";
  texto?: string;
  legenda?: string;
  responder_a?: string;
  arquivo?: { caminho?: string; nome?: string; latitude?: number; longitude?: number; name?: string; address?: string; telefone?: string };
  encaminhar_de?: string;
  template?: { nome: string; idioma: string; componentes?: unknown[]; previa?: string };
};

// envio
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);

  const auth = req.headers.get("Authorization") ?? "";
  const usuario = createClient(URL_SB, ANON, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });

  let p: Pedido;
  try { p = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }
  if (p.tipo === "template" && !p.template?.nome) return json({ ok: false, erro: "falta o modelo" }, 400);
  const credPromessa = credenciais().catch((e) => e as Error);

  if (p.encaminhar_de) {
    const enc = await usuario.rpc("wa_encaminhar_preparar", { p_mensagem: p.encaminhar_de, p_destino: p.conversa_id });
    if (enc.error || enc.data?.ok !== true) return json(enc.data ?? { ok: false, erro: "nao foi possivel encaminhar" }, 403);
    const o = enc.data;
    if (!["texto", "imagem", "audio", "video", "documento", "local", "contato"].includes(o.tipo)) return json({ ok: false, erro: "Este tipo de mensagem nao pode ser encaminhado." }, 400);
    p.tipo = o.tipo;
    p.texto = o.texto ?? undefined;
    p.legenda = o.legenda ?? undefined;
    p.responder_a = undefined;
    if (o.tipo === "local" || o.tipo === "contato") p.arquivo = o.dados ?? {};
    if (["imagem", "audio", "video", "documento"].includes(o.tipo)) {
      const ext = String(o.caminho).split(".").pop();
      const novo = `${p.conversa_id}/saida/${crypto.randomUUID()}.${ext}`;
      const cp = await sb.storage.from("wa-midia").copy(o.caminho, novo);
      if (cp.error) return json({ ok: false, erro: "nao copiou o arquivo" }, 500);
      p.arquivo = { caminho: novo, nome: o.nome ?? `arquivo.${ext}` };
    }
  }

  const prep = await usuario.rpc("wa_meta_preparar_envio", {
    p_conversa_id: p.conversa_id,
    p_id_local: p.id_local,
    p_tipo: p.tipo,
    p_texto: p.tipo === "template" ? (p.template?.previa ?? `[modelo ${p.template?.nome}]`) : (p.texto ?? null),
    p_legenda: p.legenda ?? null,
    p_arquivo: p.arquivo ?? null,
    p_responder_a: p.responder_a ?? null,
    p_modelo: p.tipo === "template" ? { nome: p.template!.nome, idioma: p.template!.idioma || "pt_BR" } : null,
  });
  if (prep.error) {
    console.error("preparar_envio", prep.error.message);
    return json({ ok: false, erro: "nao foi possivel preparar o envio" }, 400);
  }
  if (prep.data?.ok !== true) return json(prep.data ?? { ok: false, erro: "sem resposta" }, 422);
  if (prep.data.repetida) return json(prep.data);

  const msgId: string = prep.data.mensagem_id;
  const assina = (t?: string) => (prep.data.assinatura && !p.encaminhar_de && t ? `*${prep.data.assinatura}*\n${t}` : t);
  const corpo: Record<string, unknown> = {
    messaging_product: "whatsapp",
    ...(prep.data.grupo_id
      ? { recipient_type: "group", to: prep.data.grupo_id }
      : { recipient_type: "individual", ...(prep.data.telefone ? { to: prep.data.telefone } : { recipient: prep.data.bsuid }) }),
  };
  if (p.responder_a) corpo.context = { message_id: p.responder_a };

  let saiu = false;
  try {
    if (p.tipo === "texto") {
      corpo.type = "text";
      corpo.text = { body: assina(p.texto), preview_url: false };
    } else if (p.tipo === "local") {
      corpo.type = "location";
      const l = prep.data.dados;
      corpo.location = { latitude: l.latitude, longitude: l.longitude, ...(l.name ? { name: l.name } : {}), ...(l.address ? { address: l.address } : {}) };
    } else if (p.tipo === "contato") {
      const c = prep.data.dados;
      corpo.type = "contacts";
      corpo.contacts = [{ name: { formatted_name: c.nome, first_name: c.nome }, phones: [{ phone: "+" + c.telefone, wa_id: c.telefone, type: "CELL" }] }];
    } else if (p.tipo === "template") {
      corpo.type = "template";
      corpo.template = {
        name: prep.data.modelo_nome,
        language: { code: prep.data.modelo_idioma },
        ...(p.template!.componentes?.length ? { components: p.template!.componentes } : {}),
      };
    } else {
      const assinado = await sb.storage.from("wa-midia").createSignedUrl(prep.data.arquivo_caminho, 600);
      if (assinado.error) throw new Error(`arquivo: ${assinado.error.message}`);
      const tm = TIPO_META[p.tipo];
      const midia: Record<string, unknown> = { link: assinado.data.signedUrl };
      if (p.legenda && tm !== "audio") midia.caption = assina(p.legenda);
      if (tm === "document") midia.filename = p.arquivo!.nome;
      corpo.type = tm;
      corpo[tm] = midia;
    }

    const cred = await credPromessa;
    if (cred instanceof Error) throw cred;
    const { token, base } = cred;
    saiu = true;
    const r = await fetch(`${base}/${prep.data.phone_number_id}/messages`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify(corpo),
    });
    const resp = await r.json().catch(() => ({}));
    const wamid: string | undefined = resp?.messages?.[0]?.id;
    const erro = resp?.error;
    if (!wamid && r.ok && !erro) {
      await sb.rpc("wa_meta_envio_incerto", { p_mensagem_id: msgId, p_erro: "resposta da Meta sem id" });
      return json({ ok: false, mensagem_id: msgId, incerto: true, erro: "sem confirmacao da Meta: confira com o cliente antes de reenviar" }, 502);
    }

    const fim = await sb.rpc("wa_meta_resultado_envio", {
      p_mensagem_id: msgId,
      p_wamid: wamid ?? null,
      p_erro_codigo: wamid ? null : (erro?.code ?? r.status),
      p_erro: wamid ? null : (erro?.error_data?.details ?? erro?.message ?? `http ${r.status}`),
    });
    if (fim.error || fim.data !== true) {
      console.error("resultado_envio", fim.error?.message);
      return json({ ok: false, mensagem_id: msgId, erro: "nao gravou o resultado" }, 500);
    }
    if (!wamid) {
      console.error("meta", erro?.code, erro?.message);
      return json({ ok: false, mensagem_id: msgId, codigo: erro?.code, erro: erro?.code === 131047 ? "fora da janela de 24h" : "a Meta recusou a mensagem" }, 422);
    }
    if (p.encaminhar_de) {
      const enc = await sb.from("wa_mensagem").update({ encaminhada: true }).eq("id", msgId).select("id");
      if (enc.error || !enc.data?.length) console.error("encaminhada", enc.error?.message ?? "nao marcou");
    }
    return json({ ok: true, mensagem_id: msgId, wamid });
  } catch (e) {
    console.error("envio", (e as Error).message);
    if (saiu) {
      await sb.rpc("wa_meta_envio_incerto", { p_mensagem_id: msgId, p_erro: String((e as Error).message) });
      return json({ ok: false, mensagem_id: msgId, incerto: true, erro: "sem confirmacao da Meta: confira com o cliente antes de reenviar" }, 502);
    }
    await sb.rpc("wa_meta_resultado_envio", { p_mensagem_id: msgId, p_wamid: null, p_erro: String((e as Error).message) });
    return json({ ok: false, mensagem_id: msgId, erro: "falha ao enviar" }, 502);
  }
});
