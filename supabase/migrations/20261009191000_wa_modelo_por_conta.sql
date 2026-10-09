alter table public.wa_modelo add column if not exists waba_id text;
alter table public.wa_modelo add column if not exists waba_nome text;

do $$ declare d text; n text; begin
  d := pg_get_functiondef('public.wa_modelos_sincronizar(text)'::regprocedure);
  n := replace(d, $a$insert into wa_modelo (meta_id, nome, idioma, categoria, estado, motivo, componentes, atualizado_em)
      values (t->>'id', t->>'name', t->>'language', t->>'category', t->>'status', nullif(t->>'rejected_reason', 'NONE'), t->'components', now())
      on conflict (meta_id) do update set nome = excluded.nome, idioma = excluded.idioma, categoria = excluded.categoria,
        estado = excluded.estado, motivo = excluded.motivo, componentes = excluded.componentes, atualizado_em = now();$a$,
  $a$insert into wa_modelo (meta_id, nome, idioma, categoria, estado, motivo, componentes, waba_id, waba_nome, qualidade, atualizado_em)
      values (t->>'id', t->>'name', t->>'language', t->>'category', t->>'status', nullif(t->>'rejected_reason', 'NONE'), t->'components',
              p_waba, (select waba_nome from wa_numero_meta where waba_id = p_waba limit 1), t->'quality_score'->>'score', now())
      on conflict (meta_id) do update set nome = excluded.nome, idioma = excluded.idioma, categoria = excluded.categoria,
        estado = excluded.estado, motivo = excluded.motivo, componentes = excluded.componentes, waba_id = excluded.waba_id,
        waba_nome = coalesce(excluded.waba_nome, wa_modelo.waba_nome), qualidade = coalesce(excluded.qualidade, wa_modelo.qualidade), atualizado_em = now();$a$);
  n := replace(n, $a$fields=id,name,language,status,category,components,rejected_reason&limit=200$a$,
                  $a$fields=id,name,language,status,category,components,rejected_reason,quality_score&limit=200$a$);
  if n = d then raise exception 'trecho nao encontrado'; end if;
  execute n;

  d := pg_get_functiondef('public.wa_meta_painel()'::regprocedure);
  n := replace(d, $a$'atualizado_em', m.atualizado_em, 'pedido_em', m.pedido_em,$a$,
                  $a$'atualizado_em', m.atualizado_em, 'pedido_em', m.pedido_em, 'waba_id', m.waba_id, 'waba_nome', m.waba_nome,$a$);
  if n = d then raise exception 'painel nao encontrado'; end if;
  execute n;

  d := pg_get_functiondef('public.wa_modelo_pedido_resultado(uuid,jsonb,text,text,text,text)'::regprocedure);
  n := replace(d, $a$insert into wa_modelo (meta_id, nome, idioma, categoria, estado, componentes, pedido_por, pedido_em, atualizado_em)
  values (p_meta_id, p_corpo->>'name', p_corpo->>'language', coalesce(p_categoria, p_corpo->>'category'), coalesce(p_estado, 'PENDING'),
          p_corpo->'components', p_por, now(), now())$a$,
  $a$insert into wa_modelo (meta_id, nome, idioma, categoria, estado, componentes, pedido_por, pedido_em, waba_id, waba_nome, atualizado_em)
  values (p_meta_id, p_corpo->>'name', p_corpo->>'language', coalesce(p_categoria, p_corpo->>'category'), coalesce(p_estado, 'PENDING'),
          p_corpo->'components', p_por, now(), p_corpo->>'_waba', (select waba_nome from wa_numero_meta where waba_id = p_corpo->>'_waba' limit 1), now())$a$);
  if n = d then raise exception 'resultado nao encontrado'; end if;
  execute n;
end $$;
