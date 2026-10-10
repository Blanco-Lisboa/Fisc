insert into public.wa_meta_evento_tipo (campo, evento, gravidade, titulo, explicacao)
values ('account_settings_update', 'PHONE_NUMBER_SETTINGS', 'info', 'Configuração do número', 'A Meta confirmou uma mudança nas configurações do número.')
on conflict do nothing;

create or replace function public.wa_meta_evento_explicar(p_campo text, v jsonb, p_padrao text)
 returns text language sql immutable set search_path to 'pg_catalog'
as $function$
  select case
    when p_campo = 'account_settings_update' and v->>'type' = 'phone_number_settings' and v #> '{phone_number_settings,calling}' is not null then
      'A Meta confirmou: ligações pelo WhatsApp ' ||
      case upper(coalesce(v #>> '{phone_number_settings,calling,status}', '')) when 'ENABLED' then 'ligadas' when 'DISABLED' then 'desligadas' else 'com situação ' || lower(coalesce(v #>> '{phone_number_settings,calling,status}', '?')) end ||
      ' no número oficial.'
    else p_padrao end
$function$;

create or replace function public.wa_meta_conta_evento(p_campo text, v jsonb)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ev text; t wa_meta_evento_tipo%rowtype; v_num uuid; v_pnid text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  v_ev := upper(coalesce(v->>'event', v->>'decision', v->'alert_info'->>'alert_type', v->>'new_quality_score', v->>'type', ''));
  select * into t from wa_meta_evento_tipo where campo = p_campo and evento = v_ev;
  if t.campo is null then select * into t from wa_meta_evento_tipo where campo = p_campo and evento = '*'; end if;
  if t.campo is null then select * into t from wa_meta_evento_tipo where campo = '*' and evento = '*'; end if;
  v_pnid := coalesce(v->'metadata'->>'phone_number_id', v->>'phone_number_id', v #>> '{phone_number_settings,phone_number_id}');
  select id into v_num from wa_numero
   where provedor = 'meta_cloud'
     and (identificador = v_pnid
          or (coalesce(v->>'display_phone_number', v->>'phone_number') <> ''
              and telefone = regexp_replace(coalesce(v->>'display_phone_number', v->>'phone_number'), '\D', '', 'g')))
   limit 1;
  insert into wa_meta_evento (campo, evento, gravidade, titulo, explicacao, numero_id, dados)
  values (p_campo, coalesce(nullif(v_ev, ''), '-'), t.gravidade, t.titulo, wa_meta_evento_explicar(p_campo, v, t.explicacao), v_num, v);
end $function$;

update public.wa_meta_evento e
   set evento = 'PHONE_NUMBER_SETTINGS', titulo = 'Configuração do número', gravidade = 'info',
       explicacao = wa_meta_evento_explicar(e.campo, e.dados, 'A Meta confirmou uma mudança nas configurações do número.'),
       numero_id = coalesce(e.numero_id, (select n.id from wa_numero n where n.identificador = e.dados #>> '{phone_number_settings,phone_number_id}'))
 where e.campo = 'account_settings_update' and e.evento = '-' and e.dados->>'type' = 'phone_number_settings';
