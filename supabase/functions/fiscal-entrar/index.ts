import { createClient } from "npm:@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const admin = createClient(URL_SB, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const BL_URL = "https://wfqcoocfastgsfgegpcm.supabase.co";
const BL_CHAVE_PUBLICA = "sb_publishable_88ukR4t1KNTc73DxbF6-Pw_0CKW16Fe";

const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { "Content-Type": "application/json" } });

// entrada com a conta da BL
Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);
  let corpo: { bl_token?: string };
  try { corpo = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }
  if (!corpo.bl_token) return json({ ok: false, erro: "falta o login da BL" }, 400);

  const r = await fetch(`${BL_URL}/auth/v1/user`, {
    headers: { apikey: BL_CHAVE_PUBLICA, Authorization: `Bearer ${corpo.bl_token}` },
  });
  if (!r.ok) return json({ ok: false, erro: "login da BL invalido" }, 401);
  const bl = await r.json();
  if (!bl?.id || !bl?.email) return json({ ok: false, erro: "login da BL invalido" }, 401);

  const acesso = await admin.rpc("fiscal_acesso_bl", { p_usuario: bl.id });
  if (acesso.error) {
    console.error("acesso", acesso.error.message);
    return json({ ok: false, erro: "nao foi possivel conferir o acesso" }, 500);
  }
  if (acesso.data?.pode !== true) return json({ ok: false, erro: "sem acesso ao Fiscal" }, 403);

  const meta = { fiscal_nivel: acesso.data.nivel, nome: acesso.data.nome };
  const existe = await admin.auth.admin.getUserById(bl.id);
  if (existe.data?.user) {
    const up = await admin.auth.admin.updateUserById(bl.id, { email: bl.email, app_metadata: meta });
    if (up.error) { console.error("atualizar", up.error.message); return json({ ok: false, erro: "falha no login" }, 500); }
  } else {
    const cr = await admin.auth.admin.createUser({ id: bl.id, email: bl.email, email_confirm: true, app_metadata: meta });
    if (cr.error) { console.error("criar", cr.error.message); return json({ ok: false, erro: "falha no login" }, 500); }
  }

  const link = await admin.auth.admin.generateLink({ type: "magiclink", email: bl.email });
  const hash = link.data?.properties?.hashed_token;
  if (link.error || !hash) { console.error("link", link.error?.message); return json({ ok: false, erro: "falha no login" }, 500); }

  const publico = createClient(URL_SB, ANON, { auth: { persistSession: false } });
  const sessao = await publico.auth.verifyOtp({ type: "magiclink", token_hash: hash });
  if (sessao.error || !sessao.data.session) { console.error("sessao", sessao.error?.message); return json({ ok: false, erro: "falha no login" }, 500); }

  const s = sessao.data.session;
  return json({
    ok: true,
    access_token: s.access_token,
    refresh_token: s.refresh_token,
    expires_at: s.expires_at,
    usuario: { id: bl.id, nome: acesso.data.nome, nivel: acesso.data.nivel },
  });
});
