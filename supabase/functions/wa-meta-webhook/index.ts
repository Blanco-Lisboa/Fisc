import { createClient } from "npm:@supabase/supabase-js@2";

const sb = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

const LIMITE: Record<string, number> = {
  imagem: 5 * 1024 * 1024,
  audio: 16 * 1024 * 1024,
  video: 16 * 1024 * 1024,
  documento: 100 * 1024 * 1024,
  figurinha: 500 * 1024,
};

const EXT: Record<string, string> = {
  "image/jpeg": "jpg", "image/png": "png", "image/webp": "webp",
  "audio/ogg": "ogg", "audio/mpeg": "mp3", "audio/mp4": "m4a", "audio/aac": "aac", "audio/amr": "amr",
  "video/mp4": "mp4", "video/3gpp": "3gp",
  "application/pdf": "pdf", "text/plain": "txt",
};

type Midia = { midia_id: string; media_id: string; tipo: string; mensagem_id: string; conversa_id: string };

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

async function hex(buf: ArrayBuffer) {
  const d = await crypto.subtle.digest("SHA-256", buf);
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// midia
async function baixar(m: Midia) {
  try {
    const { token, base } = await credenciais();
    const r1 = await fetch(`${base}/${m.media_id}`, { headers: { Authorization: `Bearer ${token}` } });
    if (!r1.ok) throw new Error(`meta ${r1.status} ao pedir a midia`);
    const info = await r1.json();
    const limite = LIMITE[m.tipo] ?? LIMITE.documento;
    if (info.file_size && Number(info.file_size) > limite) {
      await sb.rpc("wa_meta_midia_resultado", { p_midia_id: m.midia_id, p_ok: false, p_erro: "acima do limite", p_desistir: true });
      return;
    }
    const r2 = await fetch(info.url, { headers: { Authorization: `Bearer ${token}` } });
    if (!r2.ok) throw new Error(`meta ${r2.status} ao baixar a midia`);
    const buf = await r2.arrayBuffer();
    if (buf.byteLength > limite) throw new Error("arquivo maior que o limite");
    const sha = await hex(buf);
    if (info.sha256 && String(info.sha256).toLowerCase() !== sha) throw new Error("sha256 nao confere");
    const mime = String(info.mime_type || "application/octet-stream").split(";")[0].trim();
    const caminho = `${m.conversa_id}/${m.mensagem_id}/${m.midia_id}.${EXT[mime] ?? "bin"}`;
    const up = await sb.storage.from("wa-midia").upload(caminho, buf, { contentType: mime, upsert: true });
    if (up.error) throw new Error(`bucket: ${up.error.message}`);
    const { data, error } = await sb.rpc("wa_meta_midia_resultado", {
      p_midia_id: m.midia_id, p_ok: true, p_caminho: caminho, p_tamanho: buf.byteLength, p_mime: mime, p_sha256: sha,
    });
    if (error || data !== true) throw new Error(`registro: ${error?.message ?? "nao gravou"}`);
  } catch (e) {
    await sb.rpc("wa_meta_midia_resultado", { p_midia_id: m.midia_id, p_ok: false, p_erro: String((e as Error).message) });
  }
}

// entrada
Deno.serve(async (req) => {
  const url = new URL(req.url);

  if (req.method === "GET") {
    if (url.searchParams.get("hub.mode") !== "subscribe") return new Response("", { status: 400 });
    const { data, error } = await sb.rpc("fiscal_meta_verify_ok", { p_token: url.searchParams.get("hub.verify_token") ?? "" });
    if (error || data !== true) return new Response("", { status: 403 });
    return new Response(url.searchParams.get("hub.challenge") ?? "", { status: 200, headers: { "Content-Type": "text/plain" } });
  }

  if (req.method !== "POST") return new Response("", { status: 405 });

  const tam = Number(req.headers.get("content-length") ?? "0");
  if (tam > 1024 * 1024) return new Response("", { status: 413 });
  const corpo = await req.text();
  if (corpo.length > 1024 * 1024) return new Response("", { status: 413 });
  const assinatura = req.headers.get("x-hub-signature-256");
  const conf = await sb.rpc("fiscal_meta_assinatura_ok", { p_corpo: corpo, p_assinatura: assinatura });
  if (conf.error) return new Response("", { status: 500 });
  if (conf.data !== true) return new Response("", { status: 401 });

  const rec = await sb.rpc("wa_meta_receber", { p_corpo: corpo });
  if (rec.error || rec.data?.ok !== true) return new Response("", { status: 500 });

  const fila: Midia[] = rec.data.baixar ?? [];
  if (fila.length) {
    // @ts-ignore
    EdgeRuntime.waitUntil((async () => { for (const m of fila) await baixar(m); })());
  }
  return new Response("ok", { status: 200 });
});
