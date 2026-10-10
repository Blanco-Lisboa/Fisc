drop function if exists public.fiscal_guardar_chave_bl(text);
delete from vault.secrets where name = 'bl_service_key';
