alter table public.wa_conversa drop column if exists cliente_id;

alter table public.wa_mensagem drop constraint if exists wa_mensagem_conversa_id_fkey;
alter table public.wa_mensagem add constraint wa_mensagem_conversa_id_fkey
  foreign key (conversa_id) references public.wa_conversa(id) on delete restrict;

alter table public.wa_midia drop constraint if exists wa_midia_mensagem_id_fkey;
alter table public.wa_midia add constraint wa_midia_mensagem_id_fkey
  foreign key (mensagem_id) references public.wa_mensagem(id) on delete restrict;
