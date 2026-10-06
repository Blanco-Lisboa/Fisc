create or replace function public.fiscal_pode_ver_contato(p_contato_id uuid)
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select fiscal_e_servidor() or fiscal_nivel() is not null;
$$;

create or replace function public.fiscal_pode_enviar_contato(p_contato_id uuid)
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select fiscal_e_servidor()
      or fiscal_nivel() in ('assistente', 'gerente')
      or (fiscal_nivel() = 'colaborador' and exists (
            select 1
              from wa_pessoa_vinculo v
              join wa_vinculo_alcance a on a.vinculo_id = v.id and a.ativo
             where v.contato_id = p_contato_id and v.ativo
               and a.escopo = 'empresa'
               and (a.valido_ate is null or a.valido_ate >= current_date)
               and exists (select 1 from fiscal_carteira k
                            where k.usuario_id = auth.uid() and k.empresa_id = a.empresa_id and k.ativo)
               and a.empresa_id = any(fiscal_empresas_da_you())));
$$;
revoke all on function public.fiscal_pode_enviar_contato(uuid) from public, anon;
grant execute on function public.fiscal_pode_enviar_contato(uuid) to authenticated, service_role;

drop policy if exists wa_contato_editar on wa_contato;
create policy wa_contato_editar on wa_contato for update to authenticated
  using (fiscal_pode_enviar_contato(id)) with check (fiscal_pode_enviar_contato(id));

drop policy if exists wa_conversa_editar on wa_conversa;
create policy wa_conversa_editar on wa_conversa for update to authenticated
  using (contato_id is not null and fiscal_pode_enviar_contato(contato_id))
  with check (contato_id is not null and fiscal_pode_enviar_contato(contato_id));

drop policy if exists wa_conversa_etiqueta_marcar on wa_conversa_etiqueta;
create policy wa_conversa_etiqueta_marcar on wa_conversa_etiqueta for all to authenticated
  using (exists (select 1 from wa_conversa c where c.id = wa_conversa_etiqueta.conversa_id
                  and c.contato_id is not null and fiscal_pode_enviar_contato(c.contato_id)))
  with check (exists (select 1 from wa_conversa c where c.id = wa_conversa_etiqueta.conversa_id
                  and c.contato_id is not null and fiscal_pode_enviar_contato(c.contato_id)));

create or replace function public.fiscal_exigir_acesso_vinculo()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $$
begin
  if fiscal_e_servidor() then return new; end if;
  if fiscal_nivel() is null then
    raise exception 'usuario sem cadastro no Fiscal';
  end if;
  if fiscal_nivel() not in ('assistente', 'gerente') then
    raise exception 'so assistente, gerente, diretor ou ceo vincula contato';
  end if;
  return new;
end;
$$;

do $m$
declare d text; n text;
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio(uuid,text,text,text,text,jsonb,text,jsonb)'::regprocedure);
  n := replace(d, 'fiscal_pode_ver_contato(cv.contato_id)', 'fiscal_pode_enviar_contato(cv.contato_id)');
  if n = d then raise exception 'preparar_envio: trecho nao encontrado'; end if;
  execute n;

  d := pg_get_functiondef('public.wa_contato_marcar(uuid,text,uuid,uuid,uuid[],uuid,text,text,boolean,date)'::regprocedure);
  n := replace(d, E'begin\n  if p_contato_id is null then',
    E'begin\n  if not fiscal_e_servidor() and (fiscal_nivel() is null or fiscal_nivel() not in (''assistente'', ''gerente'') or p_por is distinct from auth.uid()) then\n    raise exception ''so assistente, gerente, diretor ou ceo vincula contato'';\n  end if;\n  if p_contato_id is null then');
  if n = d then raise exception 'contato_marcar: trecho nao encontrado'; end if;
  execute n;
end $m$;
