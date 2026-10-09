alter table public.wa_chamada_permissao add column if not exists pedidos timestamptz[] not null default '{}';

create or replace function public.wa_chamada_pedir_preparar(p_conversa uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare cv wa_conversa%rowtype; k wa_contato%rowtype; nm wa_numero%rowtype; pm wa_chamada_permissao%rowtype; v_24 int; v_7 int;
begin
  if fiscal_nivel() is null then return jsonb_build_object('ok', false, 'erro', 'Usuario sem cadastro no Fiscal.'); end if;
  if not fiscal_pode('wa_ligacao_fazer') then return jsonb_build_object('ok', false, 'erro', 'Sem permissao para ligar.'); end if;
  select * into cv from wa_conversa where id = p_conversa;
  if cv.id is null or cv.grupo_meta_id is not null or not wa_pode_agir_conversa(cv.id) then
    return jsonb_build_object('ok', false, 'erro', 'Conversa nao encontrada.');
  end if;
  if not exists (select 1 from wa_mensagem where conversa_id = cv.id and direcao = 'entrada' and ocorrido_em > now() - interval '24 hours') then
    return jsonb_build_object('ok', false, 'erro', 'Fora da janela de 24h: o pedido de ligacao so vai quando o cliente escreveu nas ultimas 24h.');
  end if;
  select * into pm from wa_chamada_permissao where contato_id = cv.contato_id;
  if pm.situacao = 'permanente' then return jsonb_build_object('ok', false, 'erro', 'O cliente ja deu permissao permanente.'); end if;
  if pm.situacao = 'temporaria' and (pm.expira_em is null or pm.expira_em > now()) then
    return jsonb_build_object('ok', false, 'erro', 'O cliente ja deu permissao. Pode ligar.');
  end if;
  select count(*) filter (where x > now() - interval '24 hours'), count(*) filter (where x > now() - interval '7 days')
    into v_24, v_7 from unnest(coalesce(pm.pedidos, '{}')) x;
  if v_24 >= 1 then return jsonb_build_object('ok', false, 'erro', 'A Meta so deixa 1 pedido por dia para o mesmo cliente.'); end if;
  if v_7 >= 2 then return jsonb_build_object('ok', false, 'erro', 'A Meta so deixa 2 pedidos por semana para o mesmo cliente.'); end if;
  select * into k from wa_contato where id = cv.contato_id;
  select * into nm from wa_numero where id = cv.numero_id;
  return jsonb_build_object('ok', true, 'conversa_id', cv.id, 'phone_number_id', nm.identificador, 'telefone', k.telefone, 'bsuid', k.bsuid);
end $function$;
revoke all on function public.wa_chamada_pedir_preparar(uuid) from public, anon;
grant execute on function public.wa_chamada_pedir_preparar(uuid) to authenticated;

create or replace function public.wa_chamada_pedido_resultado(p_conversa uuid, p_autor uuid, p_wamid text, p_erro text default null)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_cont uuid;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select contato_id into v_cont from wa_conversa where id = p_conversa;
  insert into wa_mensagem (conversa_id, id_local, id_whatsapp, id_provedor, direcao, tipo, texto, status, erro, autor_id, ocorrido_em, dados)
  values (p_conversa, 'perm-' || gen_random_uuid(), nullif(p_wamid, ''), nullif(p_wamid, ''), 'saida', 'sistema',
          'Pedido de permissão para ligar', case when coalesce(p_wamid, '') <> '' then 'aguardando' else 'falhou' end,
          left(p_erro, 500), p_autor, now(), jsonb_build_object('pedido_ligacao', true));
  if coalesce(p_wamid, '') <> '' and v_cont is not null then
    insert into wa_chamada_permissao (contato_id, situacao, pedido_wamid, pedidos)
    values (v_cont, 'sem', p_wamid, array[now()])
    on conflict (contato_id) do update set pedido_wamid = excluded.pedido_wamid,
      pedidos = (select coalesce(array_agg(x), '{}') from unnest(wa_chamada_permissao.pedidos) x where x > now() - interval '7 days') || now(),
      atualizado_em = now();
  end if;
  update wa_conversa set ultima_em = now(), ultima_previa = 'Pedido de permissão para ligar', atualizado_em = now() where id = p_conversa;
  return true;
end $function$;
revoke all on function public.wa_chamada_pedido_resultado(uuid, uuid, text, text) from public, anon, authenticated;
