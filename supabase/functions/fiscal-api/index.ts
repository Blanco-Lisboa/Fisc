import { createClient } from "npm:@supabase/supabase-js@2";

const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const BL_URL = "https://wfqcoocfastgsfgegpcm.supabase.co";
const BL_CHAVE_PUBLICA = "sb_publishable_88ukR4t1KNTc73DxbF6-Pw_0CKW16Fe";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...CORS, "Content-Type": "application/json" } });

const NOME = /^[a-z_][a-z0-9_]*$/;
const PROIBIDO = /(segredo|chave|senha|token|secret|hmac|vault)/;
const FIXOS = new Set(["fiscal_bl", "fiscal_meta_config", "fiscal_api_bl_pode", "fiscal_api_bl_bloqueado"]);
const bloqueado = (n: unknown) =>
  typeof n !== "string" || !NOME.test(n) || PROIBIDO.test(n) || FIXOS.has(n) || n.startsWith("fiscal_api_bl_");
const OPS = new Set(["eq", "neq", "gt", "gte", "lt", "lte", "like", "ilike", "in", "is"]);

type Quem = { id: string; nivel: string | null; ativo: boolean };
const cache = new Map<string, Quem & { ate: number }>();

// identidade
async function quem(req: Request): Promise<Quem | null> {
  const tk = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!tk) return null;
  const h = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(tk))))
    .map((b) => b.toString(16).padStart(2, "0")).join("");
  const c = cache.get(h);
  if (c && c.ate > Date.now()) return c;
  const cab = { apikey: BL_CHAVE_PUBLICA, Authorization: `Bearer ${tk}` };
  const r = await fetch(`${BL_URL}/auth/v1/user`, { headers: cab });
  if (!r.ok) return null;
  const u = await r.json().catch(() => null);
  if (!u?.id) return null;
  const p = await fetch(`${BL_URL}/rest/v1/usuarios_internos?id=eq.${u.id}&select=nivel,ativo`, { headers: cab });
  const linha = p.ok ? (await p.json().catch(() => []))?.[0] : null;
  const q: Quem = { id: u.id, nivel: linha?.nivel ?? null, ativo: linha?.ativo === true };
  cache.set(h, { ...q, ate: Date.now() + 60_000 });
  if (cache.size > 500) cache.delete(cache.keys().next().value!);
  return q;
}

type Filtro = [string, string, unknown];
type Pedido = {
  operacao?: string; tabela?: string; funcao?: string; colunas?: string; filtros?: Filtro[];
  ordem?: [string, string][]; limite?: number; de?: number; dados?: unknown; args?: Record<string, unknown>;
};

// filtros
function aplicar(q: any, filtros: Filtro[] | undefined) {
  for (const f of filtros ?? []) {
    if (!Array.isArray(f) || f.length !== 3) throw new Error("filtro invalido");
    const [col, op, val] = f;
    if (!NOME.test(String(col)) || !OPS.has(String(op))) throw new Error("filtro invalido");
    q = op === "in" ? q.in(col, Array.isArray(val) ? val : [val]) : q[op](col, val);
  }
  return q;
}

// api
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);

  const eu = await quem(req);
  if (!eu) return json({ ok: false, erro: "login da BL invalido" }, 401);
  const usuario = eu.id;
  const pode = await admin.rpc("fiscal_api_bl_pode", { p_usuario: eu.id, p_nivel: eu.nivel, p_ativo: eu.ativo });
  if (pode.error || pode.data !== true) return json({ ok: false, erro: "sem acesso" }, 403);

  let p: Pedido;
  try { p = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }
  const op = String(p.operacao ?? "");
  const alvo = op === "rpc" ? p.funcao : p.tabela;

  const registrar = (ok: boolean, erro: string | null, linhas: number | null) =>
    admin.from("fiscal_api_bl_log").insert({ usuario_bl_id: usuario, operacao: op || "?", alvo: alvo ?? null, ok, erro, linhas });

  try {
    let r: any;
    if (op === "tabelas") r = await admin.rpc("fiscal_api_bl_tabelas");
    else if (op === "funcoes") r = await admin.rpc("fiscal_api_bl_funcoes");
    else if (op === "rpc") {
      if (bloqueado(p.funcao)) throw new Error("funcao nao permitida");
      r = await admin.rpc(p.funcao!, p.args ?? {});
    } else if (["ler", "inserir", "atualizar", "apagar"].includes(op)) {
      if (bloqueado(p.tabela)) throw new Error("tabela nao permitida");
      const t = admin.from(p.tabela!);
      if (op === "ler") {
        const lim = Math.min(Math.max(Number(p.limite ?? 100), 1), 1000);
        const de = Math.max(Number(p.de ?? 0), 0);
        let q = aplicar(t.select(p.colunas || "*", { count: "exact" }), p.filtros);
        for (const [col, dir] of p.ordem ?? []) {
          if (!NOME.test(String(col))) throw new Error("ordem invalida");
          q = q.order(col, { ascending: String(dir).toLowerCase() !== "desc" });
        }
        r = await q.range(de, de + lim - 1);
      } else if (op === "inserir") {
        if (!p.dados || typeof p.dados !== "object") throw new Error("faltam os dados");
        r = await t.insert(p.dados as any).select();
      } else {
        if (!p.filtros?.length) throw new Error("atualizar e apagar exigem filtro");
        if (op === "atualizar") {
          if (!p.dados || typeof p.dados !== "object" || Array.isArray(p.dados)) throw new Error("faltam os dados");
          r = await aplicar(t.update(p.dados as any), p.filtros).select();
        } else r = await aplicar(t.delete(), p.filtros).select();
      }
    } else throw new Error("operacao desconhecida");

    if (r.error) { await registrar(false, r.error.message, null); return json({ ok: false, erro: r.error.message }, 400); }
    const linhas = Array.isArray(r.data) ? r.data.length : null;
    await registrar(true, null, linhas);
    return json({ ok: true, dados: r.data, total: r.count ?? undefined });
  } catch (e) {
    const msg = (e as Error).message;
    await registrar(false, msg, null);
    return json({ ok: false, erro: msg }, 400);
  }
});
