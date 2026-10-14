create table if not exists public.zz_copia_diretoria_vinculos as
select now() copiado_em, 'zz_rota_provisoria_wa'::text origem, to_jsonb(z) linha from zz_rota_provisoria_wa z where numero_chave in (select numero_chave from wa_canal_diretoria)
union all select now(), 'zz_rota_provisoria_vinculo', to_jsonb(v) from zz_rota_provisoria_vinculo v where numero_chave in (select numero_chave from wa_canal_diretoria)
union all select now(), 'wa_rota_numero', to_jsonb(r) from wa_rota_numero r where telefone_chave in (select numero_chave from wa_canal_diretoria);
alter table public.zz_copia_diretoria_vinculos enable row level security;
revoke all on public.zz_copia_diretoria_vinculos from anon, authenticated;

delete from zz_rota_provisoria_wa where numero_chave in (select numero_chave from wa_canal_diretoria);
delete from zz_rota_provisoria_vinculo where numero_chave in (select numero_chave from wa_canal_diretoria);
delete from wa_rota_numero where telefone_chave in (select numero_chave from wa_canal_diretoria);

create or replace function public.wa_rota_marcar_numero(p_telefone text)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v text := wa_telefone_chave(p_telefone);
begin
  if v is null or exists (select 1 from wa_canal_diretoria d where d.numero_chave = v) then return; end if;
  insert into wa_rota_numero (telefone_chave, resolvido_em, pedido_em) values (v, null, now())
  on conflict (telefone_chave) do update set resolvido_em = null, pedido_em = now();
end $function$;

update wa_canal_diretoria set nome = case lado when 'esquerda' then 'Adrian Blanco' else 'Lucas Lisboa' end;
