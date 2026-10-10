create table if not exists public.wa_config (
  id boolean primary key default true check (id),
  confirmar_leitura boolean not null default false,
  atualizado_em timestamptz not null default now(),
  atualizado_por uuid
);
insert into public.wa_config (id) values (true) on conflict (id) do nothing;
alter table public.wa_config enable row level security;
drop policy if exists wa_config_ler on public.wa_config;
create policy wa_config_ler on public.wa_config for select to authenticated using (fiscal_pode('wa_conta_ver'));
revoke insert, update, delete on public.wa_config from anon, authenticated;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'wa_config') then
    alter publication supabase_realtime add table public.wa_config;
  end if;
end $$;

insert into public.fiscal_permissao (codigo, titulo, descricao, ordem)
values ('wa_config_gerir', 'Configurar o WhatsApp', 'Ligar ou desligar opções do WhatsApp oficial, como mostrar ao cliente que a mensagem foi vista.', 14)
on conflict (codigo) do update set titulo = excluded.titulo, descricao = excluded.descricao, ordem = excluded.ordem;
insert into public.fiscal_nivel_permissao (nivel, permissao) values ('assistente', 'wa_config_gerir'), ('gerente', 'wa_config_gerir')
on conflict do nothing;

create or replace function public.wa_config_ler()
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if not fiscal_pode('wa_conta_ver') then raise exception 'sem permissao'; end if;
  return (select jsonb_build_object('confirmar_leitura', c.confirmar_leitura, 'atualizado_em', c.atualizado_em,
                 'pode_mudar', fiscal_pode('wa_config_gerir')) from wa_config c where c.id);
end $function$;
revoke all on function public.wa_config_ler() from public, anon;
grant execute on function public.wa_config_ler() to authenticated;

create or replace function public.wa_config_gravar(p_confirmar_leitura boolean)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v boolean;
begin
  if not fiscal_pode('wa_config_gerir') then raise exception 'sem permissao'; end if;
  if p_confirmar_leitura is null then raise exception 'valor invalido'; end if;
  update wa_config set confirmar_leitura = p_confirmar_leitura, atualizado_em = now(), atualizado_por = auth.uid()
   where id returning confirmar_leitura into v;
  if v is null then raise exception 'configuracao ausente'; end if;
  return jsonb_build_object('ok', true, 'confirmar_leitura', v);
end $function$;
revoke all on function public.wa_config_gravar(boolean) from public, anon;
grant execute on function public.wa_config_gravar(boolean) to authenticated;

create or replace function public.wa_meta_acao_preparar(p_acao text, p_conversa uuid, p_mensagem uuid DEFAULT NULL::uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare cv wa_conversa%rowtype; nm wa_numero%rowtype; v_wamid text; v_ult text;
begin
  if p_acao not in ('lida', 'digitando', 'reagir', 'bloquear', 'desbloquear', 'grupo_link', 'grupo_link_novo',
                    'grupo_pedidos', 'grupo_aprovar', 'grupo_recusar', 'grupo_remover', 'grupo_editar',
                    'grupo_apagar', 'grupo_info') then
    return jsonb_build_object('ok', false, 'erro', 'Acao invalida.');
  end if;
  select * into cv from wa_conversa where id = p_conversa;
  if cv.id is null or not wa_pode_agir_conversa(cv.id) then
    return jsonb_build_object('ok', false, 'erro', 'Sem permissao nesta conversa.');
  end if;
  if p_acao like 'grupo%' and (cv.grupo_meta_id is null or not fiscal_pode('wa_grupo_gerir')) and not fiscal_e_servidor() then
    return jsonb_build_object('ok', false, 'erro', 'So gestor administra grupo.');
  end if;
  if p_acao in ('bloquear', 'desbloquear') and not fiscal_pode('wa_bloquear') and not fiscal_e_servidor() then
    return jsonb_build_object('ok', false, 'erro', 'Sem permissao para bloquear.');
  end if;
  select * into nm from wa_numero where id = cv.numero_id;
  if nm.provedor <> 'meta_cloud' or not nm.ativo then
    return jsonb_build_object('ok', false, 'erro', 'Esta conversa nao e do numero oficial.');
  end if;
  if p_mensagem is not null then
    select id_whatsapp into v_wamid from wa_mensagem where id = p_mensagem and conversa_id = cv.id and id_whatsapp not like 'imp:%';
    if v_wamid is null then return jsonb_build_object('ok', false, 'erro', 'Mensagem sem id do WhatsApp.'); end if;
  end if;
  select id_whatsapp into v_ult from wa_mensagem
   where conversa_id = cv.id and direcao = 'entrada' and id_whatsapp is not null and id_whatsapp not like 'imp:%'
   order by ocorrido_em desc limit 1;
  return jsonb_build_object('ok', true, 'phone_number_id', nm.identificador, 'telefone', cv.contato_telefone,
                            'grupo_id', cv.grupo_meta_id, 'wamid', v_wamid, 'ultima_recebida', v_ult,
                            'contato_id', cv.contato_id,
                            'confirmar_leitura', coalesce((select confirmar_leitura from wa_config where id), false));
end $function$;
