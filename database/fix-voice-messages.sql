-- Diagnostic et fix voice messages
-- 1. Vérifier/créer le bucket
do $$
begin
  if not exists (select 1 from storage.buckets where id = 'voice-messages') then
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('voice-messages', 'voice-messages', true, 5242880, array['audio/m4a', 'audio/aac', 'audio/mp4', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/webm']);
  end if;
end $$;

-- 2. Policies
drop policy if exists "Public read voice messages" on storage.objects;
create policy "Public read voice messages" on storage.objects for select using (bucket_id = 'voice-messages');

drop policy if exists "Auth upload voice messages" on storage.objects;
create policy "Auth upload voice messages" on storage.objects for insert to authenticated with check (bucket_id = 'voice-messages' and auth.role() = 'authenticated');

drop policy if exists "Users delete own voice messages" on storage.objects;
create policy "Users delete own voice messages" on storage.objects for delete to authenticated using (bucket_id = 'voice-messages' and auth.uid() = owner);

-- 3. Colonnes chat_messages
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'chat_messages') then
    if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'chat_messages' and column_name = 'voice_url') then
      alter table public.chat_messages add column voice_url text;
    end if;
    if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'chat_messages' and column_name = 'voice_duration') then
      alter table public.chat_messages add column voice_duration int default 0;
    end if;
    if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'chat_messages' and column_name = 'message_type') then
      alter table public.chat_messages add column message_type text not null default 'text';
    end if;
  end if;
end $$;
