select cron.unschedule('fiscal-copiar-legado') where exists (select 1 from cron.job where jobname = 'fiscal-copiar-legado');
