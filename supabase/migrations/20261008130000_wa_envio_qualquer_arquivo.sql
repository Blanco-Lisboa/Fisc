do $$
declare d text;
b text := E'    if v_mime in (''application/xml'', ''text/xml'', ''application/zip'', ''application/x-zip-compressed'')\n       or v_nome like ''%.xml'' or v_nome like ''%.zip'' or v_caminho like ''%.xml'' or v_caminho like ''%.zip'' then\n      return jsonb_build_object(''ok'', false, ''erro'', ''A Meta nao aceita XML nem ZIP.'');\n    end if;\n';
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio'::regproc);
  if position(b in d) > 0 then execute replace(d, b, ''); end if;
end $$;
