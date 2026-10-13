update public.zz_numero_compartilhado_wa set nome = 'Legalização YOU' where numero_chave = '5511965670720';

create or replace function public.wa_contatos_internos()
 returns table(nome text, telefone text)
 language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select x.nome, x.telefone from (
    select 'Fiscal YOU' nome, n.telefone, 0 ordem from wa_numero n
     where n.provedor = 'meta_cloud' and n.ativo and n.telefone is not null
    union all
    select s.nome, s.numero_chave, 1 from zz_numero_compartilhado_wa s
  ) x
  where fiscal_e_servidor() or fiscal_nivel() is not null
  order by x.ordem, x.nome;
$function$;
revoke all on function public.wa_contatos_internos() from public, anon;
grant execute on function public.wa_contatos_internos() to authenticated;
