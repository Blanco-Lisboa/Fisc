import { createClient } from "npm:@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const sb = createClient(URL_SB, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
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
  cache = { token: t.data as string, base, ate: Date.now() + 5 * 60 * 1000 };
  return cache as { token: string; base: string };
}

type Pedido = { acao: string; chamada_id?: string; conversa_id?: string; sdp?: string };

// ligacoes
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);
  const auth = req.headers.get("Authorization") ?? "";
  const usuario = createClient(URL_SB, ANON, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });

  let p: Pedido;
  try { p = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }
  if (p.acao === "pedir") {
    const pr = await usuario.rpc("wa_chamada_pedir_preparar", { p_conversa: p.conversa_id ?? null });
    if (pr.error) return json({ ok: false, erro: "nao foi possivel preparar" }, 400);
    if (pr.data?.ok !== true) return json(pr.data ?? { ok: false }, 403);
    const eu = await usuario.auth.getUser();
    const corpo = {
      messaging_product: "whatsapp", recipient_type: "individual",
      ...(pr.data.telefone ? { to: pr.data.telefone } : { recipient: pr.data.bsuid }),
      type: "interactive",
      interactive: { type: "call_permission_request", action: { name: "call_permission_request" },
                     body: { text: "Podemos te ligar pelo WhatsApp para resolver mais rápido?" } },
    };
    let wamid: string | null = null, erro: string | null = null;
    try {
      const { token, base } = await credenciais();
      const r = await fetch(`${base}/${pr.data.phone_number_id}/messages`, {
        method: "POST", headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" }, body: JSON.stringify(corpo),
      });
      const j = await r.json().catch(() => ({}));
      wamid = j?.messages?.[0]?.id ?? null;
      if (!wamid) erro = `${j?.error?.code ?? r.status} ${j?.error?.error_data?.details ?? j?.error?.message ?? ""}`.trim();
    } catch (e) { erro = String((e as Error).message); }
    const fim = await sb.rpc("wa_chamada_pedido_resultado", { p_conversa: pr.data.conversa_id, p_autor: eu.data.user?.id ?? null, p_wamid: wamid, p_erro: erro });
    if (fim.error) return json({ ok: false, erro: "nao gravou o pedido" }, 500);
    return wamid ? json({ ok: true, wamid }) : json({ ok: false, erro }, 422);
  }
  if (!["connect", "pre_accept", "accept", "reject", "terminate"].includes(p.acao)) return json({ ok: false, erro: "acao invalida" }, 400);
  if (["connect", "pre_accept", "accept"].includes(p.acao) && (!p.sdp || p.sdp.length > 20000)) return json({ ok: false, erro: "falta o sdp" }, 400);

  const prep = await usuario.rpc("wa_chamada_preparar", { p_acao: p.acao, p_chamada: p.chamada_id ?? null, p_conversa: p.conversa_id ?? null });
  if (prep.error) return json({ ok: false, erro: "nao foi possivel preparar" }, 400);
  const d = prep.data;
  if (d?.ok !== true) return json(d ?? { ok: false }, 403);

  const corpo: Record<string, unknown> = { messaging_product: "whatsapp", action: p.acao };
  if (p.acao === "connect") {
    if (d.telefone) corpo.to = d.telefone; else corpo.recipient = d.bsuid;
    corpo.session = { sdp_type: "offer", sdp: p.sdp };
    corpo.biz_opaque_callback_data = d.chamada_id;
  } else {
    corpo.call_id = d.wacid;
    if (p.acao === "pre_accept" || p.acao === "accept") corpo.session = { sdp_type: "answer", sdp: p.sdp };
    if (p.acao === "accept") corpo.biz_opaque_callback_data = d.chamada_id;
  }

  let r: Response, j: Record<string, any>;
  try {
    const { token, base } = await credenciais();
    r = await fetch(`${base}/${d.phone_number_id}/calls`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify(corpo),
    });
    j = await r.json().catch(() => ({}));
  } catch (e) {
    await sb.rpc("wa_chamada_resultado", { p_chamada: d.chamada_id, p_acao: p.acao, p_ok: false, p_erro: String((e as Error).message) });
    return json({ ok: false, erro: "falha ao falar com a Meta" }, 502);
  }
  const ok = r.ok && !j?.error && (j?.success === true || Array.isArray(j?.calls));
  const wacid = j?.calls?.[0]?.id ?? null;
  const erro = ok ? null : `${j?.error?.code ?? r.status} ${j?.error?.error_data?.details ?? j?.error?.message ?? ""}`.trim();
  const fim = await sb.rpc("wa_chamada_resultado", { p_chamada: d.chamada_id, p_acao: p.acao, p_ok: ok, p_wacid: wacid, p_erro: erro });
  if (fim.error || fim.data !== true) return json({ ok: false, erro: "nao gravou o resultado" }, 500);
  if (!ok) return json({ ok: false, codigo: j?.error?.code, erro: erro }, 422);
  return json({ ok: true, chamada_id: d.chamada_id, wacid });
});
