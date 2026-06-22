-- ============================================================
-- Artéïa - Améliorations chat (suppression + éphémère)
-- ============================================================

-- 1. Suppression de messages (soft delete)
alter table public.messages add column if not exists deleted_at timestamptz;
alter table public.messages add column if not exists deleted_by uuid references public.profiles(id) on delete set null;

-- 2. Messages éphémères
alter table public.messages add column if not exists is_ephemeral boolean default false;
alter table public.messages add column if not exists expires_at timestamptz;

-- 3. Index pour les messages éphémères
create index if not exists idx_messages_ephemeral on public.messages(is_ephemeral, expires_at) where is_ephemeral = true and deleted_at is null;

-- 4. Fonction de nettoyage automatique des messages éphémères
create or replace function public.cleanup_ephemeral_messages()
returns void as $$
begin
  delete from public.messages
  where is_ephemeral = true
    and expires_at < now()
    and deleted_at is null;
end;
$$ language plpgsql security definer;

-- 5. Trigger pour nettoyer les messages éphémères (toutes les heures)
create or replace function public.trigger_cleanup_ephemeral()
returns trigger as $$
begin
  perform public.cleanup_ephemeral_messages();
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists cleanup_ephemeral_trigger on public.messages;
create trigger cleanup_ephemeral_trigger
  after insert on public.messages
  for each statement
  execute function public.trigger_cleanup_ephemeral();

-- 6. RLS policies pour la suppression
drop policy if exists "Users delete own messages" on public.messages;
create policy "Users delete own messages" on public.messages
  for delete to authenticated using (auth.uid() = sender_id);

-- 7. Vue pour les messages non supprimés
create or replace view public.active_messages as
select * from public.messages
where deleted_at is null
  and (is_ephemeral = false or expires_at > now())
order by created_at asc;