update public.fiscal_info_item
   set titulo = 'Pendências', resumo = 'Aba dentro da Apuração: o que está esperando alguma ação.', atualizado_em = now()
 where id = 'pendencias';
