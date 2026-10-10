create or replace function public.wa_mensagem_edicao_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_alvo uuid; v_n int;
begin
  if new.tipo <> 'sistema' or new.direcao <> 'entrada' or coalesce(new.dados->>'nao_suportada', '') <> 'edit' then
    return new;
  end if;
  select count(*), (array_agg(id))[1] into v_n, v_alvo
    from wa_mensagem
   where conversa_id = new.conversa_id and direcao = 'entrada' and tipo in ('texto', 'imagem', 'video', 'documento')
     and apagada_em is null
     and ocorrido_em between new.ocorrido_em - interval '15 minutes' and new.ocorrido_em;
  if v_n = 1 then
    update wa_mensagem set editada_em = new.ocorrido_em,
           dados = coalesce(dados, '{}') || jsonb_build_object('edicao_sem_texto', true)
     where id = v_alvo;
    return null;
  end if;
  new.texto := 'O contato editou uma mensagem';
  return new;
end $function$;

drop trigger if exists wa_mensagem_edicao on public.wa_mensagem;
create trigger wa_mensagem_edicao before insert on public.wa_mensagem
  for each row when (new.tipo = 'sistema') execute function public.wa_mensagem_edicao_tg();
