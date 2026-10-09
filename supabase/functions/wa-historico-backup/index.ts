import { createClient } from "npm:@supabase/supabase-js@2";

const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);
  const ok = await admin.rpc("wa_historico_chave_ok", { p_chave: req.headers.get("x-chave-interna") ?? "" });
  if (ok.error || ok.data !== true) return json({ ok: false, erro: "sem permissao" }, 403);

  let p: { acao?: string; conversas?: unknown[]; caminhos?: string[]; itens?: unknown[]; midia_id?: string; erro?: string };
  try { p = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }

  if (p.acao === "lote") {
    const r = await admin.rpc("wa_historico_lote", { p_lote: p.conversas ?? [] });
    if (r.error) return json({ ok: false, erro: r.error.message }, 400);
    return json(r.data);
  }

  if (p.acao === "urls") {
    const urls: Record<string, string> = {};
    const falhas: Record<string, string> = {};
    await Promise.all((p.caminhos ?? []).slice(0, 50).map(async (c) => {
      const s = await admin.storage.from("wa-midia").createSignedUploadUrl(c, { upsert: true });
      if (s.error) falhas[c] = s.error.message; else urls[c] = s.data.signedUrl;
    }));
    return json({ ok: true, urls, falhas });
  }

  if (p.acao === "midia_ok") {
    const r = await admin.rpc("wa_historico_midia_ok", { p_itens: p.itens ?? [] });
    if (r.error) return json({ ok: false, erro: r.error.message }, 400);
    return json({ ok: true, gravadas: r.data });
  }

  if (p.acao === "midia_falhou") {
    const r = await admin.rpc("wa_historico_midia_falhou", { p_midia_id: p.midia_id, p_erro: p.erro ?? "" });
    if (r.error) return json({ ok: false, erro: r.error.message }, 400);
    return json({ ok: r.data === true });
  }

  if (p.acao === "finalizar") {
    const r = await admin.rpc("wa_historico_finalizar");
    if (r.error) return json({ ok: false, erro: r.error.message }, 400);
    return json(r.data);
  }

  return json({ ok: false, erro: "acao desconhecida" }, 400);
});
