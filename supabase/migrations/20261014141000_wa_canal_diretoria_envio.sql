create or replace function public.fiscal_pode_enviar_contato(p_contato_id uuid)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select fiscal_e_servidor()
      or fiscal_pode('departamento_ver')
      or (fiscal_nivel() is not null and exists (
            select 1 from wa_contato k
             where k.id = p_contato_id and k.telefone_chave is not null
               and (wa_rota_dono(k.telefone_chave) = auth.uid()
                    or exists (select 1 from wa_canal_diretoria d where d.numero_chave = k.telefone_chave))));
$function$;
