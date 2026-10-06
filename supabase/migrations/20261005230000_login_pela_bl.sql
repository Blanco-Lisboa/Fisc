-- quem pode entrar no Java do Fiscal (regra da BL)
create or replace function public.fiscal_acesso_bl(p_usuario uuid)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare u jsonb; m jsonb; v_nivel text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  u := fiscal_bl('usuarios_internos?select=id,nome,email,nivel,ativo&id=eq.' || p_usuario) -> 0;
  if u is null or not coalesce((u->>'ativo')::boolean, false) then
    return jsonb_build_object('pode', false);
  end if;
  m := fiscal_bl('usuario_modulos?select=modulo_codigo&modulo_codigo=eq.fiscal&usuario_id=eq.' || p_usuario);
  if jsonb_array_length(m) = 0 and coalesce(u->>'nivel', '') not in ('ceo', 'diretor') then
    return jsonb_build_object('pode', false);
  end if;
  v_nivel := case u->>'nivel' when 'colaborador' then 'colaborador' when 'assistente' then 'assistente' else 'gerente' end;
  return jsonb_build_object('pode', true, 'nivel', v_nivel, 'nome', u->>'nome', 'email', u->>'email');
end $$;
revoke all on function public.fiscal_acesso_bl(uuid) from public, anon, authenticated;
grant execute on function public.fiscal_acesso_bl(uuid) to service_role;

-- nivel vem do token emitido no login (definido pela BL), nao de cadastro proprio
create or replace function public.fiscal_nivel()
returns text
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select case when auth.jwt() -> 'app_metadata' ->> 'fiscal_nivel' in ('colaborador', 'assistente', 'gerente')
              then auth.jwt() -> 'app_metadata' ->> 'fiscal_nivel' end;
$$;
