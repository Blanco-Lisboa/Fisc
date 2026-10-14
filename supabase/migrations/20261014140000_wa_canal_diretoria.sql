create table if not exists public.wa_canal_diretoria (
  numero_chave text primary key,
  nome text not null,
  cargo text not null default 'CEO',
  lado text not null check (lado in ('esquerda', 'direita')),
  usuario_bl_id uuid,
  criado_em timestamptz not null default now(),
  unique (lado)
);
alter table public.wa_canal_diretoria enable row level security;
revoke all on public.wa_canal_diretoria from anon, authenticated;

insert into public.wa_canal_diretoria (numero_chave, nome, cargo, lado, usuario_bl_id) values
 ('5511972820660', 'Adrian', 'CEO', 'esquerda', '4c1202ac-6a7d-4c0b-93ad-6903f7eacb5d'),
 ('5511941336787', 'Lucas', 'CEO', 'direita', 'a8c06eca-8082-4f29-b49e-e7ebbebc3692')
on conflict (numero_chave) do update set nome = excluded.nome, cargo = excluded.cargo, lado = excluded.lado, usuario_bl_id = excluded.usuario_bl_id;

create or replace function public.wa_canais_diretoria()
returns table (numero_chave text, nome text, cargo text, lado text, conversa_id uuid)
language sql stable security definer set search_path = public, pg_temp as $$
  select d.numero_chave, d.nome, d.cargo, d.lado,
         (select c.id from wa_conversa c join wa_numero n on n.id = c.numero_id and n.provedor = 'meta_cloud' and n.ativo
           where not c.e_grupo and wa_telefone_chave(c.contato_telefone) = d.numero_chave
           order by c.ultima_em desc nulls last limit 1)
    from wa_canal_diretoria d
   where fiscal_e_servidor() or fiscal_nivel() is not null
   order by d.lado;
$$;
revoke execute on function public.wa_canais_diretoria() from public, anon;
grant execute on function public.wa_canais_diretoria() to authenticated;
