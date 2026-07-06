-- Schema pour la BDD Neon (secondaire)
-- Exécute CE fichier dans l'éditeur SQL de Neon
-- Ces tables stockent les données froides/archives

create table if not exists public.archive_chat_messages (
  id uuid primary key,
  channel_id uuid not null,
  author_id uuid not null,
  content text not null,
  reply_to uuid,
  attachment_url text,
  created_at timestamptz not null default now(),
  archived_at timestamptz not null default now()
);

create index if not exists idx_archive_chat_channel
  on public.archive_chat_messages(channel_id, created_at desc);

create table if not exists public.archive_community_stats (
  id uuid primary key default gen_random_uuid(),
  number_label text not null,
  label text not null,
  snapshot_date date not null default current_date,
  archived_at timestamptz not null default now()
);

create index if not exists idx_archive_stats_date
  on public.archive_community_stats(snapshot_date desc);
