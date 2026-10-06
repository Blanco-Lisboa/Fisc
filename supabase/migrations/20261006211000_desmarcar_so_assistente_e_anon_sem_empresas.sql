do $m$
declare d text; n text;
begin
  d := pg_get_functiondef('public.wa_contato_desmarcar(uuid,uuid,text)'::regprocedure);
  n := replace(d, E'begin\n  update wa_pessoa_vinculo',
    E'begin\n  if not fiscal_e_servidor() and (fiscal_nivel() is null or fiscal_nivel() not in (''assistente'', ''gerente'') or p_por is distinct from auth.uid()) then\n    raise exception ''so assistente, gerente, diretor ou ceo desfaz vinculo'';\n  end if;\n  update wa_pessoa_vinculo');
  if n = d then raise exception 'trecho nao encontrado'; end if;
  execute n;
end $m$;

revoke execute on function public.fiscal_empresas(uuid[]) from anon, public;
revoke execute on function public.fiscal_empresas_da_you() from anon, public;
revoke execute on function public.fiscal_pessoas(uuid[]) from anon, public;
grant execute on function public.fiscal_empresas(uuid[]) to authenticated, service_role;
grant execute on function public.fiscal_empresas_da_you() to authenticated, service_role;
grant execute on function public.fiscal_pessoas(uuid[]) to authenticated, service_role;
