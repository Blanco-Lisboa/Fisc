create or replace function public.wa_chamada_diagnostico(p_chamada uuid, p_dados jsonb)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ch wa_chamada%rowtype;
begin
  if fiscal_nivel() is null then return false; end if;
  if p_dados is null or jsonb_typeof(p_dados) <> 'object' or length(p_dados::text) > 4000 then return false; end if;
  select * into v_ch from wa_chamada where id = p_chamada;
  if v_ch.id is null or v_ch.atendente_id is distinct from auth.uid() then return false; end if;
  if (select count(*) from wa_chamada_evento where chamada_id = v_ch.id and tipo = 'diagnostico') >= 30 then return false; end if;
  insert into wa_chamada_evento (chamada_id, wacid, tipo, dados, ocorrido_em)
  values (v_ch.id, v_ch.wacid, 'diagnostico', p_dados, now());
  return true;
end $function$;
revoke all on function public.wa_chamada_diagnostico(uuid, jsonb) from public, anon;
grant execute on function public.wa_chamada_diagnostico(uuid, jsonb) to authenticated;
