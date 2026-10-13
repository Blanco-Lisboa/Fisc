create table if not exists public.zz_grupo_provisorio_wa (
  grupo_chave text not null,
  usuario_id uuid not null,
  mensagens int not null default 0,
  origem text not null,
  criado_em timestamptz not null default now(),
  primary key (grupo_chave, usuario_id)
);
alter table public.zz_grupo_provisorio_wa enable row level security;
revoke all on public.zz_grupo_provisorio_wa from anon, authenticated;

insert into public.zz_grupo_provisorio_wa (grupo_chave, usuario_id, mensagens, origem) values
 ('120363178688735440','8d2da2a6-2428-4043-9255-2714d2a8f11f',2,'legado_envio'),
 ('120363178688735440','297d5460-ab97-4741-8dc4-f76aec21f9fd',1,'legado_envio'),
 ('120363262289302074','022c4c1a-fd2e-4088-a570-e7419ac916b1',3,'legado_envio'),
 ('120363373039245952','f8beed8e-e59b-41e3-a9be-dcbbc0375de0',8,'legado_envio'),
 ('120363373039245952','38f92cd4-62d1-421b-9b11-e7aa183be094',7,'legado_envio'),
 ('120363373039245952','b9458e7c-6a21-430f-8c9a-acd1ba53ac27',4,'legado_envio'),
 ('120363373039245952','f049f621-6aee-4808-bcd8-0d250d96c3a2',1,'legado_envio'),
 ('120363403542285939','022c4c1a-fd2e-4088-a570-e7419ac916b1',21,'legado_envio'),
 ('120363425216402678','8d2da2a6-2428-4043-9255-2714d2a8f11f',160,'legado_envio'),
 ('120363425216402678','38f92cd4-62d1-421b-9b11-e7aa183be094',50,'legado_envio'),
 ('120363425216402678','f8beed8e-e59b-41e3-a9be-dcbbc0375de0',4,'legado_envio'),
 ('120363425216402678','b9458e7c-6a21-430f-8c9a-acd1ba53ac27',2,'legado_envio'),
 ('120363425216402678','53a325a6-cf75-45bb-b10f-62a20e14c260',2,'legado_envio'),
 ('120363425216402678','297d5460-ab97-4741-8dc4-f76aec21f9fd',1,'legado_envio'),
 ('120363426091068153','022c4c1a-fd2e-4088-a570-e7419ac916b1',7,'legado_envio'),
 ('120363426258953567','38f92cd4-62d1-421b-9b11-e7aa183be094',8,'legado_envio'),
 ('120363427142920626','022c4c1a-fd2e-4088-a570-e7419ac916b1',52,'legado_envio'),
 ('120363429343242302','b9458e7c-6a21-430f-8c9a-acd1ba53ac27',12,'legado_envio'),
 ('120363429343242302','53a325a6-cf75-45bb-b10f-62a20e14c260',9,'legado_envio'),
 ('120363429343242302','f8beed8e-e59b-41e3-a9be-dcbbc0375de0',3,'legado_envio'),
 ('120363429343242302','8d2da2a6-2428-4043-9255-2714d2a8f11f',3,'legado_envio'),
 ('120363429343242302','297d5460-ab97-4741-8dc4-f76aec21f9fd',2,'legado_envio'),
 ('120363422881046762','8d2da2a6-2428-4043-9255-2714d2a8f11f',0,'nome_do_grupo')
on conflict do nothing;

create or replace function public.zz_grupo_dono(p_chave text)
 returns uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(
    (select z.usuario_id from zz_grupo_provisorio_wa z join fiscal_usuario u on u.id = z.usuario_id and u.ativo
      where z.grupo_chave = p_chave and z.usuario_id = auth.uid()),
    (select z.usuario_id from zz_grupo_provisorio_wa z join fiscal_usuario u on u.id = z.usuario_id and u.ativo
      where z.grupo_chave = p_chave order by z.mensagens desc, z.usuario_id limit 1));
$function$;
revoke all on function public.zz_grupo_dono(text) from public, anon, authenticated;

create table if not exists public.wa_conversa_arquivo_usuario (
  conversa_id uuid not null references public.wa_conversa(id) on delete cascade,
  usuario_id uuid not null,
  arquivada_em timestamptz not null default now(),
  primary key (conversa_id, usuario_id)
);
alter table public.wa_conversa_arquivo_usuario enable row level security;
revoke all on public.wa_conversa_arquivo_usuario from anon, authenticated;

create or replace function public.wa_conversa_marcar(p_conversa uuid, p_campo text, p_valor boolean)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare n int;
begin
  if not wa_pode_agir_conversa(p_conversa) then raise exception 'sem permissao nesta conversa'; end if;
  if p_campo = 'arquivada' then
    if auth.uid() is null then raise exception 'sem usuario'; end if;
    if p_valor then
      insert into wa_conversa_arquivo_usuario (conversa_id, usuario_id) values (p_conversa, auth.uid())
      on conflict (conversa_id, usuario_id) do update set arquivada_em = now();
    else
      delete from wa_conversa_arquivo_usuario where conversa_id = p_conversa and usuario_id = auth.uid();
    end if;
    return exists (select 1 from wa_conversa where id = p_conversa);
  elsif p_campo = 'fixada' then
    if p_valor and (select count(*) from wa_conversa where fixada_em is not null and id <> p_conversa) >= 3 then
      raise exception 'no maximo 3 conversas fixadas';
    end if;
    update wa_conversa set fixada_em = case when p_valor then now() end, atualizado_em = now() where id = p_conversa;
  elsif p_campo = 'silenciada' then
    update wa_conversa set silenciada = p_valor, atualizado_em = now() where id = p_conversa;
  elsif p_campo = 'nao_lida' then
    update wa_conversa set marcada_nao_lida = p_valor, nao_lidas = case when p_valor then nao_lidas else 0 end,
                           atualizado_em = now() where id = p_conversa;
  else
    raise exception 'campo invalido';
  end if;
  get diagnostics n = row_count;
  return n = 1;
end $function$;

create or replace function public.wa_mensagem_desarquivar_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if wa_importando() then return null; end if;
  if new.direcao = 'entrada' and new.tipo <> 'sistema' then
    delete from wa_conversa_arquivo_usuario where conversa_id = new.conversa_id;
    update wa_conversa set arquivada = false where id = new.conversa_id and arquivada;
  end if;
  return null;
end $function$;
drop trigger if exists wa_mensagem_desarquivar on public.wa_mensagem;
create trigger wa_mensagem_desarquivar after insert on public.wa_mensagem
  for each row execute function public.wa_mensagem_desarquivar_tg();

insert into public.wa_conversa_arquivo_usuario (conversa_id, usuario_id)
select c.id, u.id from public.wa_conversa c cross join public.fiscal_usuario u where c.arquivada and u.ativo
on conflict do nothing;
update public.wa_conversa set arquivada = false where arquivada;

drop function if exists public.wa_painel_conversas();
create function public.wa_painel_conversas()
 returns table(conversa_id uuid, ultima_entrada timestamp with time zone, empresas uuid[], natureza text, principal boolean, responsavel_nome text, ultima_direcao text, ultima_status text, dono_id uuid, nome_provisorio text, arquivada boolean)
 language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select c.id,
         (select max(m.ocorrido_em) from wa_mensagem m where m.conversa_id = c.id and m.direcao = 'entrada'),
         coalesce((select array_agg(distinct (x->>'empresa_id')::uuid) from wa_rota_numero r, jsonb_array_elements(r.empresas) x
                    where r.telefone_chave = k.telefone_chave), '{}'),
         (select x->>'papel' from wa_rota_numero r, jsonb_array_elements(r.empresas) x where r.telefone_chave = k.telefone_chave limit 1),
         false,
         case when c.e_grupo and c.grupo_meta_id is null
              then (select string_agg(u.nome, ', ' order by z.mensagens desc) from zz_grupo_provisorio_wa z
                      join fiscal_usuario u on u.id = z.usuario_id and u.ativo where z.grupo_chave = k.telefone_chave)
              else (select u.nome from fiscal_usuario u where u.id = wa_rota_dono(k.telefone_chave)) end,
         u.direcao, u.status,
         case when c.e_grupo and c.grupo_meta_id is null then zz_grupo_dono(k.telefone_chave) else wa_rota_dono(k.telefone_chave) end,
         case when not c.e_grupo and c.grupo_meta_id is null then zz_rota_provisoria_nome(k.telefone_chave) end,
         exists (select 1 from wa_conversa_arquivo_usuario a where a.conversa_id = c.id and a.usuario_id = auth.uid())
    from wa_conversa c
    join wa_numero n on n.id = c.numero_id and n.provedor = 'meta_cloud'
    left join wa_contato k on k.id = c.contato_id
    left join lateral (select m.direcao, m.status from wa_mensagem m where m.conversa_id = c.id and m.apagada_em is null
                        order by m.ocorrido_em desc limit 1) u on true
   where c.estado <> 'arquivada' and (fiscal_e_servidor() or fiscal_nivel() is not null)
     and (c.grupo_meta_id is not null or wa_pode_ver_conversa(c.id));
$function$;
revoke all on function public.wa_painel_conversas() from public, anon;
grant execute on function public.wa_painel_conversas() to authenticated, service_role;

do $do$
declare d text;
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio(uuid,text,text,text,text,jsonb,text,jsonb)'::regprocedure);
  if position('Grupo antigo' in d) = 0 then
    d := replace(d, $a$  if not (fiscal_e_servidor() or fiscal_pode_enviar_contato(cv.contato_id)) then$a$,
                 $b$  if cv.e_grupo and cv.grupo_meta_id is null then
    return jsonb_build_object('ok', false, 'erro', 'Grupo antigo: somente leitura.');
  end if;
  if not (fiscal_e_servidor() or fiscal_pode_enviar_contato(cv.contato_id)) then$b$);
    if position('Grupo antigo' in d) = 0 then raise exception 'trava do grupo nao aplicada'; end if;
    execute d;
  end if;
end $do$;
