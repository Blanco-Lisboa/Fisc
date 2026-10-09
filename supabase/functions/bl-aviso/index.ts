import { createClient } from "npm:@supabase/supabase-js@2";

const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: { "Content-Type": "application/json" } });

// rotas
async function resolverPendentes() {
  const fim = Date.now() + 90000;
  while (Date.now() < fim) {
    const r = await sb.rpc("wa_rota_resolver", { p_limite: 8 });
    if (r.error || !r.data) return;
  }
  await sb.rpc("wa_rota_continuar");
}
async function confirmar(seq: number) {
  const c = await sb.rpc("fiscal_bl_rpc", { p_funcao: "aviso_confirmar", p_args: { p_destino: "fiscal", p_ate_seq: seq } });
  return !c.error;
}

// aviso
Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false }, 405);
  const cru = await req.text();
  if (cru.length > 65536) return json({ ok: false, erro: "grande demais" }, 413);
  const interna = req.headers.get("x-chave-interna");

  if (interna) {
    const ok = await sb.rpc("bl_aviso_chave_ok", { p_chave: interna });
    if (ok.error || ok.data !== true) return json({ ok: false }, 403);
    let p: { acao?: string };
    try { p = JSON.parse(cru); } catch { return json({ ok: false }, 400); }
    if (p.acao === "ressincronizar") {
      const r = await sb.rpc("wa_rota_ressincronizar");
      if (r.error) return json({ ok: false, erro: "ressincronia falhou", detalhe: r.error.message }, 502);
      await confirmar(Number(r.data?.ultimo_seq ?? 0));
    }
    if (p.acao === "resolver" || p.acao === "ressincronizar") { await resolverPendentes(); return json({ ok: true }); }
    return json({ ok: false }, 400);
  }

  if (req.headers.get("x-bl-destino") !== "fiscal") return json({ ok: false }, 403);
  const ass = await sb.rpc("wa_bl_aviso_assinatura_ok", { p_corpo: cru, p_assinatura: req.headers.get("x-bl-assinatura") ?? "" });
  if (ass.error || ass.data !== true) return json({ ok: false, erro: "assinatura" }, 401);
  let ev: { destino?: string; seq?: number; tipo?: string; payload?: unknown };
  try { ev = JSON.parse(cru); } catch { return json({ ok: false }, 400); }
  if (ev.destino !== "fiscal" || !Number.isInteger(ev.seq)) return json({ ok: false }, 400);

  const a = await sb.rpc("wa_rota_aplicar", { p_seq: ev.seq, p_tipo: ev.tipo ?? "", p_payload: ev.payload ?? {} });
  if (a.error) return json({ ok: false, erro: "nao aplicou" }, 500);
  if (a.data === "buraco") {
    const r = await sb.rpc("wa_rota_ressincronizar");
    if (r.error) return json({ ok: false, erro: "ressincronia falhou" }, 502);
    await confirmar(Number(r.data?.ultimo_seq ?? 0));
  } else {
    await confirmar(ev.seq as number);
  }
  await sb.rpc("wa_rota_continuar");
  return json({ ok: true, resultado: a.data });
});
