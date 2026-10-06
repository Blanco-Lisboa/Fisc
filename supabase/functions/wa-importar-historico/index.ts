import { createClient } from "npm:@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const admin = createClient(URL_SB, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { "Content-Type": "application/json" } });

// importacao do historico do celular
Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);
  const usuario = createClient(URL_SB, ANON, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    auth: { persistSession: false },
  });
  const nivel = await usuario.rpc("fiscal_nivel");
  if (nivel.error || !["assistente", "gerente"].includes(nivel.data)) return json({ ok: false, erro: "sem permissao" }, 403);

  let p: { acao?: string; telefone_numero?: string; conversas?: unknown[]; midia_id?: string; caminho?: string; tamanho?: number };
  try { p = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }

  if (p.acao === "lote") {
    const r = await admin.rpc("wa_importar_lote", { p_telefone_numero: p.telefone_numero, p_lote: p.conversas ?? [] });
    if (r.error) { console.error("lote", r.error.message); return json({ ok: false, erro: r.error.message }, 400); }
    const envios = [];
    for (const m of r.data.midias ?? []) {
      const s = await admin.storage.from("wa-midia").createSignedUploadUrl(m.caminho);
      if (s.error) { console.error("upload", s.error.message); continue; }
      envios.push({ ...m, url: s.data.signedUrl });
    }
    return json({ ok: true, novas: r.data.novas, repetidas: r.data.repetidas, envios });
  }

  if (p.acao === "midia_ok") {
    const r = await admin.rpc("wa_importar_midia_ok", { p_midia_id: p.midia_id, p_caminho: p.caminho, p_tamanho: p.tamanho ?? null });
    if (r.error || r.data !== true) return json({ ok: false, erro: "nao gravou" }, 400);
    return json({ ok: true });
  }

  return json({ ok: false, erro: "acao desconhecida" }, 400);
});
