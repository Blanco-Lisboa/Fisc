import { createClient } from "npm:@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const sb = createClient(URL_SB, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
};
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...CORS, "Content-Type": "application/json" } });

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
  cache = { token: t.data as string, base, ate: Date.now() + 50 * 60 * 1000 };
  return cache as { token: string; base: string };
}

async function graph(metodo: string, caminho: string, corpo?: unknown) {
  const { token, base } = await credenciais();
  const r = await fetch(`${base}/${caminho}`, {
    method: metodo,
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    ...(corpo ? { body: JSON.stringify(corpo) } : {}),
  });
  const j = await r.json().catch(() => ({}));
  return { ok: r.ok && !j?.error, status: r.status, j };
}

function erroMeta(j: Record<string, any>) {
  const e = j?.error ?? {};
  if (e.code === 131009) return "Não dá para reagir a esta mensagem: ela tem mais de 30 dias, foi apagada ou não existe mais na conversa.";
  if (e.code === 131047) return "A Meta só permite isto com quem escreveu nas últimas 24 horas.";
  if (e.code === 131021) return "Não é possível bloquear o próprio número.";
  if (e.code === 139101) return "A lista de bloqueados chegou ao limite.";
  if (e.code === 131215) return "Este número ainda não tem acesso a grupos na Meta (precisa ser Conta Comercial Oficial).";
  return e.error_data?.details ?? e.message ?? "A Meta recusou o pedido.";
}

type Pedido = {
  acao: string;
  conversa_id?: string;
  mensagem_id?: string;
  emoji?: string;
  pedidos?: string[];
  participantes?: string[];
  nome?: string;
  descricao?: string;
  aprovar_entrada?: boolean;
};

const MSG = (to: string, grupo: boolean) => ({
  messaging_product: "whatsapp",
  recipient_type: grupo ? "group" : "individual",
  to,
});

// acoes
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, erro: "metodo" }, 405);
  const auth = req.headers.get("Authorization") ?? "";
  const usuario = createClient(URL_SB, ANON, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });

  let p: Pedido;
  try { p = await req.json(); } catch { return json({ ok: false, erro: "corpo invalido" }, 400); }

  try {
    if (p.acao === "grupo_criar") {
      const pode = await usuario.rpc("fiscal_pode", { p_permissao: "wa_grupo_criar" });
      if (pode.error || pode.data !== true) return json({ ok: false, erro: "Sem permissao para criar grupo." }, 403);
      const nome = String(p.nome ?? "").trim();
      if (!nome || nome.length > 100) return json({ ok: false, erro: "Nome do grupo obrigatorio (ate 100 letras)." }, 400);
      const num = await sb.from("wa_numero").select("identificador").eq("provedor", "meta_cloud").eq("ativo", true).limit(1).maybeSingle();
      if (num.error || !num.data) return json({ ok: false, erro: "Numero oficial nao encontrado." }, 400);
      const r = await graph("POST", `${num.data.identificador}/groups`, {
        messaging_product: "whatsapp",
        subject: nome,
        ...(p.descricao ? { description: String(p.descricao).slice(0, 2048) } : {}),
        join_approval_mode: p.aprovar_entrada === false ? "auto_approve" : "approval_required",
      });
      if (!r.ok) return json({ ok: false, erro: erroMeta(r.j), codigo: r.j?.error?.code }, 422);
      const gid = r.j?.id ?? r.j?.group_id;
      let conversa: string | null = null;
      if (gid) {
        const eu = await usuario.auth.getUser();
        const reg = await sb.rpc("wa_grupo_registrar", {
          p_numero_identificador: num.data.identificador, p_grupo_id: gid, p_nome: nome,
          p_descricao: p.descricao ?? null, p_link: r.j?.invite_link ?? null, p_por: eu.data.user?.id ?? null,
        });
        if (reg.error) return json({ ok: false, erro: "Grupo criado na Meta mas nao registrado: " + reg.error.message }, 500);
        conversa = reg.data as string;
      }
      return json({ ok: true, grupo_id: gid ?? null, conversa_id: conversa });
    }

    if (!p.conversa_id) return json({ ok: false, erro: "falta a conversa" }, 400);
    const prep = await usuario.rpc("wa_meta_acao_preparar", {
      p_acao: p.acao, p_conversa: p.conversa_id, p_mensagem: p.mensagem_id ?? null,
    });
    if (prep.error) return json({ ok: false, erro: "nao foi possivel preparar" }, 400);
    const d = prep.data;
    if (d?.ok !== true) return json(d ?? { ok: false }, 403);

    const fim = async (dados: unknown = {}) => {
      const g = await sb.rpc("wa_meta_acao_resultado", { p_acao: p.acao, p_conversa: p.conversa_id, p_mensagem: p.mensagem_id ?? null, p_dados: dados });
      if (g.error) throw new Error("registro: " + g.error.message);
    };
    const pid = d.phone_number_id as string;
    const gid = d.grupo_id as string | null;
    let r;

    switch (p.acao) {
      case "lida":
      case "digitando": {
        if (!d.ultima_recebida) { if (p.acao === "lida") await fim(); return json({ ok: true, sem_mensagem: true }); }
        if (d.confirmar_leitura !== true) { if (p.acao === "lida") await fim(); return json({ ok: true, sem_aviso: true }); }
        r = await graph("POST", `${pid}/messages`, {
          messaging_product: "whatsapp", status: "read", message_id: d.ultima_recebida,
          ...(p.acao === "digitando" ? { typing_indicator: { type: "text" } } : {}),
        });
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        if (p.acao === "lida") await fim();
        return json({ ok: true });
      }
      case "reagir": {
        const emoji = String(p.emoji ?? "");
        if ([...emoji].length > 16) return json({ ok: false, erro: "emoji invalido" }, 400);
        const destino = gid ?? d.telefone;
        if (!destino) return json({ ok: false, erro: "Conversa sem telefone." }, 400);
        r = await graph("POST", `${pid}/messages`, {
          ...MSG(destino, !!gid), type: "reaction", reaction: { message_id: d.wamid, emoji },
        });
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        await fim({ emoji });
        return json({ ok: true });
      }
      case "bloquear":
      case "desbloquear": {
        if (!d.telefone) return json({ ok: false, erro: "Conversa sem telefone." }, 400);
        r = await graph(p.acao === "bloquear" ? "POST" : "DELETE", `${pid}/block_users`, {
          messaging_product: "whatsapp", block_users: [{ user: d.telefone }],
        });
        const falhou = r.j?.block_users?.failed_users?.[0];
        if (!r.ok || falhou) return json({ ok: false, erro: falhou?.errors?.[0]?.message ?? erroMeta(r.j) }, 422);
        await fim();
        return json({ ok: true });
      }
      case "grupo_info":
        r = await graph("GET", `${gid}?fields=subject,description,participants,total_participant_count,join_approval_mode,suspended`);
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        return json({ ok: true, grupo: r.j });
      case "grupo_link":
      case "grupo_link_novo":
        r = await graph(p.acao === "grupo_link" ? "GET" : "POST", `${gid}/invite_link`, p.acao === "grupo_link" ? undefined : { messaging_product: "whatsapp" });
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        await fim({ invite_link: r.j?.invite_link });
        return json({ ok: true, link: r.j?.invite_link });
      case "grupo_pedidos":
        r = await graph("GET", `${gid}/join_requests`);
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        return json({ ok: true, pedidos: r.j?.data ?? [] });
      case "grupo_aprovar":
      case "grupo_recusar": {
        const ids = (p.pedidos ?? []).map(String).slice(0, 100);
        if (!ids.length) return json({ ok: false, erro: "nenhum pedido" }, 400);
        r = await graph(p.acao === "grupo_aprovar" ? "POST" : "DELETE", `${gid}/join_requests`, { messaging_product: "whatsapp", join_requests: ids });
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        return json({ ok: true, resultado: r.j });
      }
      case "grupo_remover": {
        const ps = (p.participantes ?? []).map(String).slice(0, 8);
        if (!ps.length) return json({ ok: false, erro: "nenhum participante" }, 400);
        r = await graph("DELETE", `${gid}/participants`, { messaging_product: "whatsapp", participants: ps.map((u) => ({ user: u })) });
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        return json({ ok: true });
      }
      case "grupo_editar": {
        const corpo: Record<string, unknown> = { messaging_product: "whatsapp" };
        if (p.nome) corpo.subject = String(p.nome).slice(0, 100);
        if (p.descricao !== undefined) corpo.description = String(p.descricao).slice(0, 2048);
        r = await graph("POST", `${gid}`, corpo);
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        await fim({ subject: corpo.subject ?? "", description: corpo.description });
        return json({ ok: true });
      }
      case "grupo_apagar":
        r = await graph("DELETE", `${gid}`);
        if (!r.ok) return json({ ok: false, erro: erroMeta(r.j) }, 422);
        await fim();
        return json({ ok: true });
    }
    return json({ ok: false, erro: "acao invalida" }, 400);
  } catch (e) {
    console.error("acao", p.acao, (e as Error).message);
    return json({ ok: false, erro: "falha ao falar com a Meta" }, 502);
  }
});
