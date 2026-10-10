import { createClient } from "jsr:@supabase/supabase-js@2";

const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});
const BUCKET = "fiscal-app";
const SHA = /^[0-9a-f]{64}$/;

function resp(status: number, corpo: unknown) {
  return new Response(JSON.stringify(corpo), { status, headers: { "content-type": "application/json" } });
}

async function existentes(): Promise<Map<string, number>> {
  const mapa = new Map<string, number>();
  for (let pag = 0; ; pag++) {
    const { data, error } = await sb.storage.from(BUCKET).list("arquivos", { limit: 1000, offset: pag * 1000 });
    if (error) throw error;
    for (const o of data ?? []) mapa.set(o.name, Number((o.metadata as Record<string, unknown>)?.size ?? -1));
    if (!data || data.length < 1000) break;
  }
  return mapa;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return resp(405, { ok: false, erro: "metodo" });
  const { data: ok, error: e1 } = await sb.rpc("fiscal_app_publicador_ok", { p_token: req.headers.get("x-publicar-token") ?? "" });
  if (e1 || ok !== true) return resp(401, { ok: false, erro: "nao_autorizado" });

  let corpo: Record<string, unknown>;
  try { corpo = await req.json(); } catch { return resp(400, { ok: false, erro: "json" }); }

  try {
    if (corpo.acao === "faltando") {
      const lista = (corpo.arquivos as { sha256: string; tamanho: number }[]) ?? [];
      if (!lista.every((a) => SHA.test(a.sha256))) return resp(400, { ok: false, erro: "sha256" });
      const tem = await existentes();
      const faltam = [];
      for (const a of lista) {
        if (tem.get(a.sha256) === a.tamanho) continue;
        const { data, error } = await sb.storage.from(BUCKET).createSignedUploadUrl("arquivos/" + a.sha256, { upsert: true });
        if (error) throw error;
        faltam.push({ sha256: a.sha256, url: data.signedUrl });
      }
      return resp(200, { ok: true, faltam });
    }

    if (corpo.acao === "publicar") {
      const versao = String(corpo.versao ?? "");
      const aplicativo = String(corpo.aplicativo ?? "fiscal");
      const manifesto = corpo.manifesto as { principal?: string; arquivos?: { sha256: string; tamanho: number }[]; lancador?: { sha256: string; tamanho: number } };
      if (!versao || !manifesto?.principal || !manifesto.arquivos?.length) return resp(400, { ok: false, erro: "manifesto" });
      const tem = await existentes();
      const todos = [...manifesto.arquivos, ...(manifesto.lancador ? [manifesto.lancador] : [])];
      const ausentes = todos.filter((a) => !SHA.test(a.sha256) || tem.get(a.sha256) !== a.tamanho).map((a) => a.sha256);
      if (ausentes.length) return resp(409, { ok: false, erro: "arquivos_ausentes", ausentes });
      const { data, error } = await sb.rpc("fiscal_app_publicar", { p_aplicativo: aplicativo, p_versao: versao, p_manifesto: manifesto });
      if (error) throw error;
      return resp(200, data);
    }
    return resp(400, { ok: false, erro: "acao" });
  } catch (e) {
    return resp(500, { ok: false, erro: String((e as Error)?.message ?? e) });
  }
});
