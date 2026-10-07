create or replace function public.fiscal_central_gestor()
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_you uuid[];
begin
  if not fiscal_e_servidor() and coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente') then
    raise exception 'so gestor do Fiscal';
  end if;
  v_you := fiscal_empresas_da_you();
  return jsonb_build_object(
    'carga', coalesce((
      select jsonb_agg(jsonb_build_object('usuario_id', x.id, 'nome', x.nome, 'clientes', x.n) order by x.n desc, x.nome)
        from (select u.id, u.nome,
                     (select count(*) from fiscal_carteira k where k.usuario_id = u.id and k.ativo and k.empresa_id = any(v_you)) n
                from fiscal_usuario u where u.ativo) x), '[]'::jsonb),
    'xml_aberto', '[]'::jsonb,
    'ciclo', jsonb_build_object('etapas', '[]'::jsonb, 'clientes', '[]'::jsonb),
    'alertas', '{}'::jsonb);
end $$;
revoke all on function public.fiscal_central_gestor() from public, anon;
grant execute on function public.fiscal_central_gestor() to authenticated, service_role;
