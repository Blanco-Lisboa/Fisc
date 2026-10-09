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

const CAMPOS_NUMERO = ["id", "display_phone_number", "verified_name", "quality_rating", "name_status", "status",
  "code_verification_status", "platform_type", "throughput", "is_official_business_account",
  "whatsapp_business_manager_messaging_limit"];
const CAMPOS_NUMERO_BASE = ["id", "display_phone_number", "verified_name", "quality_rating", "name_status", "status"];

// meta
async function meta() {
  const [t, c] = await Promise.all([sb.rpc("fiscal_meta_segredo", { p_slot: "token" }), sb.rpc("fiscal_meta_config")]);
  if (t.error) throw new Error("token");
  if (c.error) throw new Error("config");
  const raiz = (c.data.base_url || "https://graph.facebook.com").replace(/\/+$/, "");
  const base = /\/v\d+(\.\d+)?$/.test(raiz) ? raiz : `${raiz}/${c.data.versao}`;
  return { token: t.data as string, base, waba: c.data.waba_id as string, pnid: c.data.phone_number_id as string };
}
async function graph(m: { token: string; base: string }, caminho: string, init: RequestInit = {}) {
  const r = await fetch(`${m.base}/${caminho}`, { ...init, headers: { Authorization: `Bearer ${m.token}`, "Content-Type": "application/json" } });
  const j = await r.json().catch(() => ({}));
  return { ok: r.ok && !j?.error, j };
}

// gestao
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);
  const usuario = createClient(URL_SB, ANON, { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } }, auth: { persistSession: false } });
  let p: { acao?: string; modelo?: unknown };
  try { p = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }
  const eu = await usuario.auth.getUser();
  if (!eu.data.user) return json({ ok: false, erro: "sem login" }, 401);

  if (p.acao === "sincronizar") {
    const pode = await usuario.rpc("fiscal_pode", { p_permissao: "wa_conta_ver" });
    if (pode.error || pode.data !== true) return json({ ok: false, erro: "Sem permissão." }, 403);
    let m;
    try { m = await meta(); } catch { return json({ ok: false, erro: "Configuração da Meta indisponível." }, 502); }
    const num = await sb.from("wa_numero").select("id").eq("provedor", "meta_cloud").eq("identificador", m.pnid).maybeSingle();
    if (num.error || !num.data) return json({ ok: false, erro: "Número da Meta não cadastrado." }, 500);
    let fone = await graph(m, `${m.pnid}?fields=${CAMPOS_NUMERO.join(",")}`);
    if (!fone.ok) fone = await graph(m, `${m.pnid}?fields=${CAMPOS_NUMERO_BASE.join(",")}`);
    const waba = await graph(m, `${m.waba}?fields=id,name,account_review_status`);
    if (!fone.ok) return json({ ok: false, erro: `A Meta não respondeu sobre o número (${fone.j?.error?.code ?? "?"}).` }, 502);
    const g = await sb.rpc("wa_numero_meta_gravar", { p_numero: num.data.id, p_waba: waba.ok ? waba.j : { id: m.waba }, p_fone: fone.j });
    if (g.error || g.data !== true) return json({ ok: false, erro: "Não gravou os dados do número." }, 500);
    const s = await sb.rpc("wa_modelos_sincronizar", { p_waba: m.waba });
    if (s.error) return json({ ok: false, erro: "Não foi possível atualizar os modelos." }, 502);
    return json({ ok: true, modelos: s.data?.modelos ?? 0 });
  }

  if (p.acao === "pedir_modelo") {
    const prep = await usuario.rpc("wa_modelo_pedido_preparar", { p: p.modelo ?? {} });
    if (prep.error) return json({ ok: false, erro: "Não foi possível conferir o modelo." }, 400);
    if (prep.data?.ok !== true) return json(prep.data ?? { ok: false }, 422);
    let m;
    try { m = await meta(); } catch { return json({ ok: false, erro: "Configuração da Meta indisponível." }, 502); }
    const corpo = prep.data.corpo;
    const r = await graph(m, `${m.waba}/message_templates`, { method: "POST", body: JSON.stringify(corpo) });
    const erro = r.ok ? null : [r.j?.error?.code, r.j?.error?.error_user_title, r.j?.error?.error_user_msg ?? r.j?.error?.message]
      .filter((x) => x !== undefined && x !== null && String(x) !== "").join(" | ");
    const fim = await sb.rpc("wa_modelo_pedido_resultado", { p_por: eu.data.user.id, p_corpo: { ...corpo, _waba: m.waba }, p_meta_id: r.ok ? String(r.j.id) : null,
      p_estado: r.ok ? (r.j.status ?? "PENDING") : null, p_categoria: r.ok ? (r.j.category ?? null) : null, p_erro: erro });
    if (fim.error) return json({ ok: false, erro: "Não gravou o resultado." }, 500);
    if (!r.ok) return json({ ok: false, erro: r.j?.error?.error_user_msg ?? r.j?.error?.message ?? "A Meta recusou o pedido." }, 422);
    return json({ ok: true, id: fim.data?.id, estado: r.j.status ?? "PENDING" });
  }

  return json({ ok: false, erro: "acao invalida" }, 400);
});
