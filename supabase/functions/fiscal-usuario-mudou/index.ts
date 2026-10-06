import { createClient } from "npm:@supabase/supabase-js@2";

const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { "Content-Type": "application/json" } });

// aviso da BL: usuario mudou, reler a fonte
Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false }, 405);
  let corpo: { usuario_id?: string };
  try { corpo = await req.json(); } catch { return json({ ok: false }, 400); }
  const id = String(corpo.usuario_id ?? "");
  if (!UUID.test(id)) return json({ ok: false }, 400);
  const r = await admin.rpc("fiscal_usuario_sincronizar", { p_usuario: id });
  if (r.error) {
    console.error("sincronizar", r.error.message);
    return json({ ok: false }, 500);
  }
  return json({ ok: true });
});
