-- ============================================================
-- Artéïa - Système de Messagerie v3
-- ============================================================

-- 1. CANAUX DE DISCUSSION (chat rooms)
create table if not exists public.channels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  type text not null check (type in ('general', 'category', 'group', 'direct')) default 'general',
  category text,
  icon text default '💬',
  created_by uuid references public.profiles(id) on delete set null,
  is_private boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. MEMBRES DES CANAUX (pour les canaux privés/groupes)
create table if not exists public.channel_members (
  channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('member', 'moderator', 'admin')) default 'member',
  joined_at timestamptz not null default now(),
  primary key (channel_id, user_id)
);

-- 3. MESSAGES
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  user_name text not null default 'Anonyme',
  content text not null,
  is_voice boolean not null default false,
  voice_url text,
  voice_duration int default 0,
  reply_to uuid references public.messages(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. LECTURES (suivi des messages lus par utilisateur)
create table if not exists public.message_reads (
  user_id uuid not null references public.profiles(id) on delete cascade,
  channel_id uuid not null references public.channels(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (user_id, channel_id)
);

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists idx_messages_channel_time 
  on public.messages (channel_id, created_at desc);
create index if not exists idx_messages_user 
  on public.messages (user_id, created_at desc);
create index if not exists idx_channels_category 
  on public.channels (category);
create index if not exists idx_channel_members_user 
  on public.channel_members (user_id);

-- ============================================================
-- CANAUX PAR DÉFAUT
-- ============================================================
insert into public.channels (name, description, type, icon) values
  ('Général', 'Discussion générale pour tous les artistes', 'general', '💬'),
  ('Annonces', 'Annonces importantes de la communauté', 'general', '📢'),
  ('Musique', 'Partagez vos créations musicales', 'category', '🎵'),
  ('Arts Visuels', 'Galerie et discussions artistiques', 'category', '🎨'),
  ('Littérature', 'Poèmes, histoires et écrits', 'category', '✍️'),
  ('Manga', 'Mangas et illustrations japonaises', 'category', '📚'),
  ('Films', 'Cinéma et productions vidéo', 'category', '🎬'),
  ('Animation', 'Animations et motion design', 'category', '🎞️')
on conflict do nothing;

-- ============================================================
-- REALTIME (activation pour les messages)
-- ============================================================
alter publication supabase_realtime add table public.messages;

-- ============================================================
-- RLS POLICIES
-- ============================================================
alter table public.channels enable row level security;
alter table public.channel_members enable row level security;
alter table public.messages enable row level security;
alter table public.message_reads enable row level security;

-- Canaux : tout le monde peut lire, utilisateurs connectés peuvent créer
drop policy if exists "Public read channels" on public.channels;
create policy "Public read channels" on public.channels 
  for select using (true);

drop policy if exists "Auth create channels" on public.channels;
create policy "Auth create channels" on public.channels
  for insert to authenticated with check (auth.uid() = created_by);

-- Messages : tout le monde peut lire, utilisateurs connectés peuvent écrire
drop policy if exists "Public read messages" on public.messages;
create policy "Public read messages" on public.messages 
  for select using (true);

drop policy if exists "Auth insert messages" on public.messages;
create policy "Auth insert messages" on public.messages
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users update own messages" on public.messages;
create policy "Users update own messages" on public.messages
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Channel members : géré par les admins
drop policy if exists "Public read channel members" on public.channel_members;
create policy "Public read channel members" on public.channel_members
  for select using (true);