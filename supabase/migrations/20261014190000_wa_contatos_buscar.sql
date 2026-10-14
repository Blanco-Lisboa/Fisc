create or replace function public.wa_contatos_buscar(p_texto text)
returns table (nome text, telefone text)
language sql stable security definer set search_path = public, pg_temp as $$
  with q as (select lower(btrim(coalesce(p_texto, ''))) t, regexp_replace(coalesce(p_texto, ''), '\D', '', 'g') d),
  base as (
    select z.nome, z.numero_chave telefone from zz_rota_provisoria_wa z
     where nullif(btrim(z.nome), '') is not null
       and (z.usuario_id = auth.uid() or fiscal_pode('departamento_ver'))),
  achados as (
    select b.nome, b.telefone,
           case when lower(b.nome) = q.t then 0
                when lower(b.nome) like q.t || '%' then 1
                when lower(b.nome) like '% ' || q.t || '%' then 2
                when lower(b.nome) like '%' || q.t || '%' then 3
                when length(q.d) >= 3 and b.telefone like '%' || q.d then 4
                else 5 end ordem
      from base b, q
     where fiscal_nivel() is not null and length(q.t) >= 2
       and (lower(b.nome) like '%' || q.t || '%' or (length(q.d) >= 3 and b.telefone like '%' || q.d || '%')))
  select nome, telefone from achados order by ordem, length(nome), nome limit 12;
$$;
revoke execute on function public.wa_contatos_buscar(text) from public, anon;
grant execute on function public.wa_contatos_buscar(text) to authenticated;
