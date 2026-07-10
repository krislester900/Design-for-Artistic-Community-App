-- ============================================================
-- Artéïa - Storage bucket pour les messages vocaux
-- ============================================================

-- 1. Création du bucket voice-messages (public read, authenticated write)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'voice-messages',
  'voice-messages',
  true,
  5242880, -- 5 MB max per file
  array['audio/m4a', 'audio/aac', 'audio/mp4', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/webm']
)
on conflict (id) do nothing;

-- 2. RLS policies pour le bucket voice-messages
drop policy if exists "Public read voice messages" on storage.objects;
create policy "Public read voice messages" on storage.objects
  for select using (bucket_id = 'voice-messages');

drop policy if exists "Auth upload voice messages" on storage.objects;
create policy "Auth upload voice messages" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'voice-messages'
    and auth.role() = 'authenticated'
  );

drop policy if exists "Users delete own voice messages" on storage.objects;
create policy "Users delete own voice messages" on storage.objects
  for delete to authenticated using (
    bucket_id = 'voice-messages'
    and auth.uid() = owner
  );
