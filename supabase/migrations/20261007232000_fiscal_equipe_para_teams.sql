create or replace function public.fiscal_equipe()
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_us jsonb; v_rel jsonb; v_set jsonb;
begin
  if not fiscal_e_servidor() and fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  v_us := fiscal_bl('usuarios_internos?select=id,nome,email,nivel,foto_url&ativo=eq.true&order=nome&limit=1000');
  v_rel := fiscal_bl('usuario_setores?select=usuario_id,setor_id,principal&limit=5000');
  v_set := fiscal_bl('setores?select=id,nome&eh_departamento=eq.true&order=nome&limit=200');
  return jsonb_build_object(
    'setores', v_set,
    'pessoas', (select coalesce(jsonb_agg(u || jsonb_build_object('setores',
                  (select coalesce(jsonb_agg(r->>'setor_id' order by (r->>'principal')::boolean desc nulls last), '[]'::jsonb)
                     from jsonb_array_elements(v_rel) r
                    where r->>'usuario_id' = u->>'id'
                      and exists (select 1 from jsonb_array_elements(v_set) s where s->>'id' = r->>'setor_id')))), '[]'::jsonb)
                  from jsonb_array_elements(v_us) u));
end $$;
revoke all on function public.fiscal_equipe() from public, anon;
grant execute on function public.fiscal_equipe() to authenticated, service_role;
