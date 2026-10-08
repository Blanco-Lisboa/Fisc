create or replace function public.wa_painel_conversas()
returns table(conversa_id uuid, ultima_entrada timestamptz, empresas uuid[], natureza text, principal boolean, responsavel_nome text)
language sql stable security definer set search_path to 'public', 'pg_temp' as $$
  select c.id,
         (select max(m.ocorrido_em) from wa_mensagem m where m.conversa_id = c.id and m.direcao = 'entrada'),
         coalesce((select array_agg(distinct a.empresa_id) from wa_pessoa_vinculo v
                     join wa_vinculo_alcance a on a.vinculo_id = v.id and a.ativo and a.escopo = 'empresa'
                    where v.contato_id = c.contato_id and v.ativo and a.empresa_id is not null), '{}'),
         (select v.natureza from wa_pessoa_vinculo v where v.contato_id = c.contato_id and v.ativo
           order by v.principal desc, v.vinculado_em desc limit 1),
         coalesce((select bool_or(v.principal) from wa_pessoa_vinculo v where v.contato_id = c.contato_id and v.ativo), false),
         (select u.nome from fiscal_usuario u where u.id = c.responsavel_id)
    from wa_conversa c
    join wa_numero n on n.id = c.numero_id and n.provedor = 'meta_cloud'
   where c.estado <> 'arquivada' and (fiscal_e_servidor() or fiscal_nivel() is not null)
     and (c.grupo_meta_id is not null or wa_pode_ver_conversa(c.id));
$$;
revoke all on function public.wa_painel_conversas() from public, anon;
grant execute on function public.wa_painel_conversas() to authenticated, service_role;

create or replace function public.wa_ficha_conversa(p_conversa uuid)
returns jsonb
language plpgsql stable security definer set search_path to 'public', 'pg_temp' as $$
declare c wa_conversa%rowtype; r jsonb;
begin
  if not (fiscal_e_servidor() or fiscal_nivel() is not null) then raise exception 'sem acesso'; end if;
  select * into c from wa_conversa where id = p_conversa;
  if c.id is null or not (c.grupo_meta_id is not null or wa_pode_ver_conversa(c.id)) then raise exception 'conversa nao encontrada'; end if;
  select jsonb_build_object(
    'contato_criado_em', (select k.criado_em from wa_contato k where k.id = c.contato_id),
    'primeiro_em', coalesce(c.primeiro_em, (select min(m.ocorrido_em) from wa_mensagem m where m.conversa_id = c.id)),
    'msgs_mes', (select count(*) from wa_mensagem m where m.conversa_id = c.id and m.apagada_em is null
                   and m.ocorrido_em >= date_trunc('month', now())),
    'responsavel', (select u.nome from fiscal_usuario u where u.id = c.responsavel_id),
    'pode_vincular', fiscal_e_servidor() or fiscal_nivel() in ('assistente', 'gerente'),
    'vinculos', coalesce((select jsonb_agg(jsonb_build_object(
        'id', v.id, 'natureza', v.natureza, 'principal', v.principal, 'cargo', v.cargo, 'pessoa_nome', v.pessoa_nome,
        'titular', v.titular_pessoa_id, 'confianca', v.confianca,
        'alcance', coalesce((select jsonb_agg(jsonb_build_object('empresa_id', a.empresa_id, 'escopo', a.escopo, 'nivel', a.nivel,
                                  'areas', a.areas, 'valido_ate', a.valido_ate) order by a.liberado_em)
                               from wa_vinculo_alcance a where a.vinculo_id = v.id and a.ativo), '[]'))
        order by v.principal desc, v.vinculado_em)
      from wa_pessoa_vinculo v where v.contato_id = c.contato_id and v.ativo), '[]'),
    'carteira', coalesce((select jsonb_agg(distinct jsonb_build_object('empresa_id', k.empresa_id, 'usuario', u.nome))
      from fiscal_carteira k join fiscal_usuario u on u.id = k.usuario_id
     where k.ativo and k.empresa_id in (select a.empresa_id from wa_pessoa_vinculo v
                                          join wa_vinculo_alcance a on a.vinculo_id = v.id and a.ativo
                                         where v.contato_id = c.contato_id and v.ativo)), '[]')
  ) into r;
  return r;
end $$;
revoke all on function public.wa_ficha_conversa(uuid) from public, anon;
grant execute on function public.wa_ficha_conversa(uuid) to authenticated, service_role;

create or replace function public.fiscal_pessoas_da_empresa(p_empresa uuid)
returns table(pessoa_id uuid, nome text, cpf_fim text)
language plpgsql stable security definer set search_path to 'public', 'pg_temp' as $$
begin
  if not (fiscal_e_servidor() or fiscal_nivel() in ('assistente', 'gerente')) then raise exception 'so gestor'; end if;
  if p_empresa is null or not (fiscal_e_servidor() or fiscal_pode_ver_empresa(p_empresa)) then return; end if;
  return query
  select distinct (r->>'pessoa_id')::uuid, r->>'nome', right(regexp_replace(coalesce(r->>'cpf', ''), '\D', '', 'g'), 4)
    from jsonb_array_elements(fiscal_bl('you_pessoas_para_fiscal?select=pessoa_id,nome,cpf&empresa_id=eq.' || p_empresa)) r
   where r->>'pessoa_id' is not null
   order by 2;
end $$;
revoke all on function public.fiscal_pessoas_da_empresa(uuid) from public, anon;
grant execute on function public.fiscal_pessoas_da_empresa(uuid) to authenticated, service_role;

do $$
declare d text;
b text := E'  if p_tipo = ''template'' then\n    select * into md from wa_modelo\n     where nome = p_modelo->>''nome'' and idioma = coalesce(p_modelo->>''idioma'', ''pt_BR'') and estado = ''APPROVED''\n     limit 1;\n    if md.id is null then\n      return jsonb_build_object(''ok'', false, ''erro'', ''Modelo nao aprovado pela Meta.'');\n    end if;\n';
n text := b || E'    v_dados := jsonb_build_object(''modelo'', md.nome);\n';
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio'::regproc);
  if position(n in d) = 0 and position(b in d) > 0 then execute replace(d, b, n); end if;
end $$;
