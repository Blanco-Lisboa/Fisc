create or replace function public.wa_meta_nao_suportada_texto(m jsonb)
 returns text language sql immutable set search_path to 'pg_catalog'
as $function$
  select case
    when m #>> '{errors,0,code}' = '131060' then 'Mensagem ainda indisponível na Meta'
    else case m #>> '{unsupported,type}'
      when 'edit' then 'Mensagem editada pelo cliente'
      when 'reaction' then 'Reação do cliente'
      when 'poll_creation' then 'Enquete enviada pelo cliente'
      when 'poll_update' then 'Voto em enquete'
      when 'pin' then 'Mensagem fixada pelo cliente'
      when 'keep_in_chat' then 'Mensagem mantida na conversa'
      when 'group_invite' then 'Convite para grupo'
      when 'gif' then 'GIF'
      when 'image' then 'Foto de visualização única'
      when 'location' then 'Localização em tempo real'
      when 'media_placeholder' then 'Mídia indisponível'
      when 'order' then 'Pedido do catálogo'
      when 'product' then 'Produto do catálogo'
      when 'link_preview' then 'Link'
      when 'button' then 'Mensagem com botões'
      when 'list' then 'Mensagem com lista'
      when 'interactive' then 'Mensagem interativa'
      when 'hsm' then 'Mensagem de modelo'
      else 'Mensagem que a Meta não repassa' end
  end
$function$;

do $$
declare d text := pg_get_functiondef('public.wa_meta_receber'::regproc);
begin
  if (length(d) - length(replace(d, $a$when 'unsupported' then 'mensagem nao suportada'$a$, ''))) / length($a$when 'unsupported' then 'mensagem nao suportada'$a$) <> 1 then
    raise exception 'trecho do texto nao encontrado uma unica vez';
  end if;
  if (length(d) - length(replace(d, $a$when 'location' then m->'location'$a$, ''))) / length($a$when 'location' then m->'location'$a$) <> 1 then
    raise exception 'trecho dos dados nao encontrado uma unica vez';
  end if;
  d := replace(d, $a$when 'unsupported' then 'mensagem nao suportada'$a$, $b$when 'unsupported' then wa_meta_nao_suportada_texto(m)$b$);
  d := replace(d, $a$when 'location' then m->'location'$a$,
               $b$when 'unsupported' then jsonb_strip_nulls(jsonb_build_object('nao_suportada', m->'unsupported'->>'type', 'erro', m->'errors'->0->>'code', 'detalhe', m->'errors'->0->'error_data'->>'details'))
              when 'location' then m->'location'$b$);
  execute d;
end $$;

update public.wa_mensagem set texto = 'Mensagem que a Meta não repassa'
 where texto = 'mensagem nao suportada' and tipo = 'sistema';
