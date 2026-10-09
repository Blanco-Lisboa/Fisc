alter table public.fiscal_config add column if not exists bl_setor_fiscal uuid;
update public.fiscal_config set bl_setor_fiscal = '85aa9f03-b91d-4d25-9f6d-366c6fe2d813' where bl_setor_fiscal is null;

create or replace function public.fiscal_acesso_bl(p_usuario uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare u jsonb; v_setor uuid; m jsonb; v_nivel text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select bl_setor_fiscal into v_setor from fiscal_config limit 1;
  if v_setor is null then raise exception 'setor Fiscal nao configurado'; end if;
  u := fiscal_bl('usuarios_internos?select=id,nome,email,nivel,ativo&id=eq.' || p_usuario) -> 0;
  if u is null or not coalesce((u->>'ativo')::boolean, false) then
    return jsonb_build_object('pode', false);
  end if;
  m := fiscal_bl('usuario_setores?select=usuario_id&usuario_id=eq.' || p_usuario || '&setor_id=eq.' || v_setor);
  if jsonb_array_length(m) = 0 then
    return jsonb_build_object('pode', false);
  end if;
  v_nivel := case u->>'nivel' when 'colaborador' then 'colaborador' when 'assistente' then 'assistente' else 'gerente' end;
  return jsonb_build_object('pode', true, 'nivel', v_nivel, 'nome', u->>'nome', 'email', u->>'email');
end $function$;
revoke all on function public.fiscal_acesso_bl(uuid) from public, anon, authenticated;
grant execute on function public.fiscal_acesso_bl(uuid) to service_role;

create or replace function public.fiscal_usuarios_ressincronizar()
 returns int language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_setor uuid; lista jsonb; r record; n int := 0;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select bl_setor_fiscal into v_setor from fiscal_config limit 1;
  lista := fiscal_bl('usuario_setores?select=usuario_id&setor_id=eq.' || v_setor || '&limit=1000');
  for r in select distinct (x->>'usuario_id')::uuid id from jsonb_array_elements(lista) x loop
    perform fiscal_usuario_sincronizar(r.id); n := n + 1;
  end loop;
  update fiscal_usuario set ativo = false
   where ativo and id not in (select (x->>'usuario_id')::uuid from jsonb_array_elements(lista) x);
  return n;
end $function$;
revoke all on function public.fiscal_usuarios_ressincronizar() from public, anon, authenticated;

do $$ declare d text; n text; begin
  d := pg_get_functiondef('public.wa_rota_aplicar(bigint,text,jsonb)'::regprocedure);
  n := replace(d, $a$  if p_payload ? 'aberta' and v_emp is not null then$a$,
$a$  if p_tipo = 'usuario' or (p_payload ? 'usuario_id' and not p_payload ? 'aberta') then
    perform fiscal_usuario_sincronizar((p_payload->>'usuario_id')::uuid);
  elsif p_payload ? 'aberta' and v_emp is not null then$a$);
  if n = d then raise exception 'aplicar nao mudou'; end if;
  execute n;
  d := pg_get_functiondef('public.wa_rota_ressincronizar()'::regprocedure);
  n := replace(d, $a$  update fiscal_sync set ultimo_seq = v_seq, estado = 'ok'$a$,
                  $a$  perform fiscal_usuarios_ressincronizar();
  update fiscal_sync set ultimo_seq = v_seq, estado = 'ok'$a$);
  if n = d then raise exception 'ressincronizar nao mudou'; end if;
  execute n;
end $$;

create or replace function public.fiscal_mapa_departamento()
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if not fiscal_e_servidor() and not fiscal_pode('painel_gestor') then
    raise exception 'so gestor do Fiscal';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', u.id, 'nome', u.nome, 'nivel', u.nivel, 'foto_url', null, 'entrada_hoje', null, 'atencao', false,
             'carteira', (select count(*) from wa_rota_carteira k where k.dono_id = u.id))
           order by u.nome)
      from fiscal_usuario u
     where u.ativo), '[]'::jsonb);
end $function$;
