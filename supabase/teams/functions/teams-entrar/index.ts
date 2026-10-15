import { createClient } from "npm:@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const admin = createClient(URL_SB, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const BL_URL = "https://wfqcoocfastgsfgegpcm.supabase.co";
const BL_CHAVE = "sb_publishable_88ukR4t1KNTc73DxbF6-Pw_0CKW16Fe";
const FISCAL_URL = "https://vvohwixeokxydmbhqklu.supabase.co";
const FISCAL_CHAVE = "sb_publishable_jQVklnYdEmsbVYzsp7_0Nw_ZLht78GM";
const LEGAL_URL = "https://ynqcmzukahkmqbvirlkb.supabase.co";
const LEGAL_CHAVE = "sb_publishable_YWo2MLN_-IBgo9cIMmOezw_tCD5cWz6";
const LEGADO_URL = "https://uvmcfnghdsmpzhijqlos.supabase.co";
const LEGADO_CHAVE = "sb_publishable_p91YPpnGsvmy4ccIncwoaw_dFszF86t";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...CORS, "Content-Type": "application/json" } });

type Quem = { id: string; email: string; nome: string; setores: string[] };

async function lerSetores(url: string, init: RequestInit, ler: (d: unknown) => string[]): Promise<string[]> {
  try { const r = await fetch(url, init); return r.ok ? ler(await r.json()) : []; } catch { return []; }
}

async function pelaBl(token: string): Promise<Quem | null> {
  const r = await fetch(`${BL_URL}/auth/v1/user`, { headers: { apikey: BL_CHAVE, Authorization: `Bearer ${token}` } });
  if (!r.ok) return null;
  const u = await r.json();
  if (!u?.id || !u?.email) return null;
  const q = await fetch(`${BL_URL}/rest/v1/usuarios_internos?select=id,nome,ativo&id=eq.${u.id}`, {
    headers: { apikey: BL_CHAVE, Authorization: `Bearer ${token}` },
  });
  if (!q.ok) return null;
  const linhas = await q.json();
  const ui = Array.isArray(linhas) ? linhas[0] : null;
  if (!ui || ui.ativo === false) return null;
  const setores = await lerSetores(`${BL_URL}/rest/v1/usuario_setores?select=setor_id&usuario_id=eq.${u.id}`,
    { headers: { apikey: BL_CHAVE, Authorization: `Bearer ${token}` } },
    (d) => Array.isArray(d) ? d.map((x: { setor_id: string }) => x.setor_id) : []);
  return { id: u.id, email: u.email, nome: ui.nome ?? u.email, setores };
}

const DEPARTAMENTOS = [
  { url: FISCAL_URL, chave: FISCAL_CHAVE },
  { url: LEGAL_URL, chave: LEGAL_CHAVE },
];

async function peloDepartamento(url: string, chave: string, token: string): Promise<Quem | null> {
  const r = await fetch(`${url}/auth/v1/user`, { headers: { apikey: chave, Authorization: `Bearer ${token}` } });
  if (!r.ok) return null;
  const u = await r.json();
  const nivel = u?.app_metadata?.fiscal_nivel;
  if (!u?.id || !u?.email || !["colaborador", "assistente", "gerente"].includes(nivel)) return null;
  const setores = await lerSetores(`${url}/rest/v1/rpc/fiscal_meus_setores`,
    { method: "POST", headers: { apikey: chave, Authorization: `Bearer ${token}`, "Content-Type": "application/json" }, body: "{}" },
    (d) => Array.isArray(d) ? d.map(String) : []);
  return { id: u.id, email: u.email, nome: u.app_metadata?.nome ?? u.email, setores };
}

async function peloFiscal(token: string): Promise<Quem | null> {
  for (const d of DEPARTAMENTOS) {
    const q = await peloDepartamento(d.url, d.chave, token).catch(() => null);
    if (q) return q;
  }
  return null;
}

async function peloLegado(token: string): Promise<Quem | null> {
  const r = await fetch(`${LEGADO_URL}/auth/v1/user`, { headers: { apikey: LEGADO_CHAVE, Authorization: `Bearer ${token}` } });
  if (!r.ok) return null;
  const u = await r.json();
  if (!u?.id || !u?.email) return null;
  const q = await fetch(`${LEGADO_URL}/rest/v1/usuarios_internos?select=id,nome,ativo&id=eq.${u.id}`, {
    headers: { apikey: LEGADO_CHAVE, Authorization: `Bearer ${token}` },
  });
  if (!q.ok) return null;
  const linhas = await q.json();
  const ui = Array.isArray(linhas) ? linhas[0] : null;
  if (!ui || ui.ativo === false) return null;
  return { id: u.id, email: u.email, nome: ui.nome ?? u.email, setores: [] };
}

// entrada no TEAM's com o login da BL ou de um sistema do grupo
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);
  let corpo: { bl_token?: string; fiscal_token?: string; legado_token?: string };
  try { corpo = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }

  let quem: Quem | null = null;
  if (corpo.bl_token) quem = await pelaBl(corpo.bl_token);
  else if (corpo.fiscal_token) quem = await peloFiscal(corpo.fiscal_token);
  else if (corpo.legado_token) quem = await peloLegado(corpo.legado_token);
  else return json({ ok: false, erro: "falta o login" }, 400);
  if (!quem) return json({ ok: false, erro: "sem acesso ao TEAM's" }, 403);

  const meta = { interno: true, nome: quem.nome, setores: quem.setores };
  const existe = await admin.auth.admin.getUserById(quem.id);
  if (existe.data?.user) {
    const up = await admin.auth.admin.updateUserById(quem.id, { email: quem.email, app_metadata: meta });
    if (up.error) { console.error("atualizar", up.error.message); return json({ ok: false, erro: "falha no login" }, 500); }
  } else {
    const cr = await admin.auth.admin.createUser({ id: quem.id, email: quem.email, email_confirm: true, app_metadata: meta });
    if (cr.error) { console.error("criar", cr.error.message); return json({ ok: false, erro: "falha no login" }, 500); }
  }

  if (corpo.fiscal_token && quem.setores.length) {
    const sinc = await admin.rpc("chat_membro_sincronizar", { p_usuario: quem.id, p_setores: quem.setores });
    if (sinc.error) console.error("sincronizar", sinc.error.message);
  }

  const link = await admin.auth.admin.generateLink({ type: "magiclink", email: quem.email });
  const hash = link.data?.properties?.hashed_token;
  if (link.error || !hash) { console.error("link", link.error?.message); return json({ ok: false, erro: "falha no login" }, 500); }
  const publico = createClient(URL_SB, ANON, { auth: { persistSession: false } });
  const sessao = await publico.auth.verifyOtp({ type: "magiclink", token_hash: hash });
  if (sessao.error || !sessao.data.session) { console.error("sessao", sessao.error?.message); return json({ ok: false, erro: "falha no login" }, 500); }
  const s = sessao.data.session;
  return json({ ok: true, access_token: s.access_token, refresh_token: s.refresh_token, expires_at: s.expires_at,
                usuario: { id: quem.id, nome: quem.nome } });
});
