create or replace function public.fiscal_acesso_bl(p_usuario uuid)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare u jsonb; v_emp text; v_setor text; m jsonb; v_nivel text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  u := fiscal_bl('usuarios_internos?select=id,nome,email,nivel,ativo&id=eq.' || p_usuario) -> 0;
  if u is null or not coalesce((u->>'ativo')::boolean, false) then
    return jsonb_build_object('pode', false);
  end if;
  v_emp := fiscal_bl('empresas?select=id&slug=eq.you') -> 0 ->> 'id';
  if v_emp is null then raise exception 'empresa YOU nao encontrada na BL'; end if;
  v_setor := fiscal_bl('setores?select=id&nome=eq.Fiscal&eh_departamento=eq.true&empresa_id=eq.' || v_emp) -> 0 ->> 'id';
  if v_setor is null then raise exception 'departamento Fiscal da YOU nao encontrado na BL'; end if;
  m := fiscal_bl('usuario_setores?select=usuario_id&usuario_id=eq.' || p_usuario || '&setor_id=eq.' || v_setor);
  if jsonb_array_length(m) = 0 then
    return jsonb_build_object('pode', false);
  end if;
  v_nivel := case u->>'nivel' when 'colaborador' then 'colaborador' when 'assistente' then 'assistente' else 'gerente' end;
  return jsonb_build_object('pode', true, 'nivel', v_nivel, 'nome', u->>'nome', 'email', u->>'email');
end $$;
revoke all on function public.fiscal_acesso_bl(uuid) from public, anon, authenticated;
grant execute on function public.fiscal_acesso_bl(uuid) to service_role;
