do $m$
declare d text; n text;
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio(uuid,text,text,text,text,jsonb,text,jsonb)'::regprocedure);
  n := replace(d,
    E'if cv.id is null or not (fiscal_e_servidor() or (cv.contato_id is not null and fiscal_pode_enviar_contato(cv.contato_id))) then\n    return jsonb_build_object(''ok'', false, ''erro'', ''Conversa nao encontrada.'');\n  end if;',
    E'if cv.id is null or not (fiscal_e_servidor() or (cv.contato_id is not null and fiscal_pode_ver_contato(cv.contato_id))) then\n    return jsonb_build_object(''ok'', false, ''erro'', ''Conversa nao encontrada.'');\n  end if;\n  if not (fiscal_e_servidor() or fiscal_pode_enviar_contato(cv.contato_id)) then\n    return jsonb_build_object(''ok'', false, ''erro'', ''Contato nao vinculado a uma empresa da sua carteira.'');\n  end if;');
  if n = d then raise exception 'trecho nao encontrado'; end if;
  execute n;
end $m$;
