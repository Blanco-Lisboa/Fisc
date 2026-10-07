do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'wa_midia') then
    alter publication supabase_realtime add table public.wa_midia;
  end if;
end $$;
