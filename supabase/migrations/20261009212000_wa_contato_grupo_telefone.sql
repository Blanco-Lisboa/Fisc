alter table public.wa_contato drop constraint if exists wa_contato_telefone_ck;
alter table public.wa_contato add constraint wa_contato_telefone_ck check (telefone ~ '^[0-9]{10,15}$' or (e_grupo and telefone ~ '^[0-9]{10,40}$'));
