import { createClient } from "npm:@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const LK_KEY = Deno.env.get("LIVEKIT_API_KEY") ?? "";
const LK_SECRET = Deno.env.get("LIVEKIT_API_SECRET") ?? "";
const LK_URL = Deno.env.get("LIVEKIT_URL") ?? "";
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...CORS, "Content-Type": "application/json" } });

const b64url = (b: Uint8Array | string) => {
  const bytes = typeof b === "string" ? new TextEncoder().encode(b) : b;
  let s = "";
  bytes.forEach((x) => (s += String.fromCharCode(x)));
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};

async function assinar(claims: Record<string, unknown>) {
  const cab = b64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const corpo = b64url(JSON.stringify(claims));
  const chave = await crypto.subtle.importKey("raw", new TextEncoder().encode(LK_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", chave, new TextEncoder().encode(`${cab}.${corpo}`)));
  return `${cab}.${corpo}.${b64url(sig)}`;
}

// passe da ligacao
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);
  if (!LK_KEY || !LK_SECRET || !LK_URL) return json({ ok: false, erro: "ligacao_nao_configurada" }, 503);
  const auth = req.headers.get("Authorization") ?? "";
  const usuario = createClient(URL_SB, ANON, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });
  let corpo: { canal_id?: string };
  try { corpo = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }
  const canal = String(corpo.canal_id ?? "");
  if (!UUID.test(canal)) return json({ ok: false, erro: "conversa invalida" }, 400);

  const eu = await usuario.auth.getUser();
  const u = eu.data.user;
  if (eu.error || !u || u.app_metadata?.interno !== true) return json({ ok: false, erro: "sem acesso" }, 403);
  const pode = await usuario.rpc("chat_pode_ver_canal", { p_canal: canal });
  if (pode.error || pode.data !== true) return json({ ok: false, erro: "sem acesso a esta conversa" }, 403);

  const agora = Math.floor(Date.now() / 1000);
  const token = await assinar({
    iss: LK_KEY, sub: u.id, nbf: agora - 10, exp: agora + 60 * 60 * 4,
    name: String(u.app_metadata?.nome ?? u.email ?? "Usuário").slice(0, 80),
    video: { room: canal, roomJoin: true, canPublish: true, canSubscribe: true, canPublishData: true },
  });
  return json({ ok: true, url: LK_URL, token });
});
