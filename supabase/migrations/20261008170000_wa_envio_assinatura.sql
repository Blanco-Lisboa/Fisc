do $$
declare d text;
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio'::regproc);
  if position('''assinatura''' in d) = 0 then
    d := replace(d, 'length(p_texto) > 4096', 'length(p_texto) > 4040');
    d := replace(d, 'length(coalesce(p_legenda, '''')) > 1024', 'length(coalesce(p_legenda, '''')) > 970');
    d := replace(d, '''arquivo_caminho'', v_caminho, ''arquivo_mime'', v_mime);',
      '''arquivo_caminho'', v_caminho, ''arquivo_mime'', v_mime,' || E'\n' ||
      '                            ''assinatura'', (select initcap(nullif(split_part(btrim(u.nome), '' '', 1), '''')) || '' - Fiscal You'' from fiscal_usuario u where u.id = auth.uid()));');
    if position('''assinatura''' in d) = 0 then raise exception 'nao achei o ponto de troca'; end if;
    execute d;
  end if;
end $$;
