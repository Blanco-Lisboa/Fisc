create or replace function public.wa_chamada_toque(p_chamada uuid)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare v_chave text; v_dono uuid; v_nome text;
begin
  if fiscal_nivel() is null or not fiscal_pode('wa_ligacao_atender') then return jsonb_build_object('tocar', false); end if;
  select k.telefone_chave into v_chave
    from wa_chamada ch join wa_conversa c on c.id = ch.conversa_id join wa_contato k on k.id = c.contato_id
   where ch.id = p_chamada and ch.direcao = 'cliente';
  if v_chave is null then return jsonb_build_object('tocar', false); end if;
  if exists (select 1 from wa_canal_diretoria d where d.numero_chave = v_chave) then
    return jsonb_build_object('tocar', true, 'modo', 'livre');
  end if;
  v_dono := wa_rota_dono(v_chave);
  if v_dono = auth.uid() then return jsonb_build_object('tocar', true, 'modo', 'dono'); end if;
  if fiscal_pode('departamento_ver') then
    if v_dono is null then return jsonb_build_object('tocar', true, 'modo', 'livre'); end if;
    select nome into v_nome from fiscal_usuario where id = v_dono;
    return jsonb_build_object('tocar', true, 'modo', 'gestor', 'dono_id', v_dono, 'dono_nome', v_nome);
  end if;
  return jsonb_build_object('tocar', false);
end $$;
revoke execute on function public.wa_chamada_toque(uuid) from public, anon;
grant execute on function public.wa_chamada_toque(uuid) to authenticated;
