-- Supabase / PostgreSQL schema for Artistic Community App
-- Run this file in the Supabase SQL editor.
-- This schema creates an empty pre-launch database.

-- ============================================================
-- ATTENTION: L'ordre des CREATE TABLE est critique.
-- Les tables référencées doivent exister avant celles qui
-- les référencent via des clés étrangères.
-- Ordre corrigé :
--   1. Types énumérés
--   2. categories
--   3. profiles
--   4. artists, artworks, forum_discussions, trend_tags,
--      community_events, community_stats
--   5. chat_channels, chat_channel_members, chat_messages,
--      chat_groups, chat_group_members, user_relationships,
--      user_presence
-- ============================================================

create extension if not exists pgcrypto;

create type public.category_slug as enum (
  'music',
  'visual-art',
  'manga',
  'film',
  'literature',
  'animation'
);

create type public.section_id as enum (
  'artists',
  'showcase',
  'forum'
);

create type public.app_role as enum (
  'user',
  'admin'
);

-- === CHAT SYSTEM (Discord-like) ===

create type public.channel_type as enum (
  'public',
  'private',
  'dm'
);

create type public.member_role as enum (
  'owner',
  'admin',
  'member'
);

create type public.relationship_status as enum (
  'pending',
  'accepted',
  'blocked'
);

create type public.user_presence_status as enum (
  'online',
  'idle',
  'offline'
);

-- ============================================================
-- 1. CATEGORIES (déclarée en premier, référencée par artists,
--    artworks, forum_discussions, trend_tags, community_events,
--    chat_channels)
-- ============================================================

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  slug public.category_slug unique not null,
  title text not null,
  short_label text not null,
  description text not null,
  image text not null,
  color text not null,
  target_section_id public.section_id not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 2. PROFILES (référencée par artists, artworks, chat_*,
--    user_relationships, user_presence)
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role public.app_role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 3. TABLES CONTENU (référencent categories et/ou profiles)
-- ============================================================

create table if not exists public.artists (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_slug public.category_slug not null references public.categories(slug) on delete restrict,
  role text not null,
  image text not null,
  featured_work text not null,
  likes integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.artworks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist_name text not null,
  category_slug public.category_slug not null references public.categories(slug) on delete restrict,
  medium text not null,
  image text not null,
  likes integer not null default 0,
  views integer not null default 0,
  height text not null default 'aspect-square',
  created_at timestamptz not null default now()
);

create table if not exists public.forum_discussions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author_name text not null,
  category_slug public.category_slug not null references public.categories(slug) on delete restrict,
  replies integer not null default 0,
  time_label text not null,
  trending boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.trend_tags (
  id uuid primary key default gen_random_uuid(),
  tag text not null unique,
  count_label text not null default '0',
  category_slug public.category_slug not null references public.categories(slug) on delete restrict,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.community_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  date_label text not null,
  category_slug public.category_slug not null references public.categories(slug) on delete restrict,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.community_stats (
  id uuid primary key default gen_random_uuid(),
  number_label text not null default '0',
  label text not null unique,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 4. TABLES CHAT (référencent categories et profiles)
-- ============================================================

create table if not exists public.chat_channels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type public.channel_type not null default 'public',
  category_slug public.category_slug references public.categories(slug) on delete set null,
  description text not null default '',
  background_image text,
  created_by uuid not null references public.profiles(id) on delete cascade,
  is_locked boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_channel_members (
  channel_id uuid not null references public.chat_channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.member_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (channel_id, user_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.chat_channels(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  reply_to uuid references public.chat_messages(id) on delete set null,
  attachment_url text,
  edited_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  image text,
  created_by uuid not null references public.profiles(id) on delete cascade,
  max_members integer not null default 10000,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_group_members (
  group_id uuid not null references public.chat_groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.member_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table if not exists public.user_relationships (
  requester_id uuid not null references public.profiles(id) on delete cascade,
  target_id uuid not null references public.profiles(id) on delete cascade,
  status public.relationship_status not null default 'pending',
  created_at timestamptz not null default now(),
  primary key (requester_id, target_id),
  constraint different_users check (requester_id <> target_id)
);

create table if not exists public.user_presence (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  status public.user_presence_status not null default 'offline',
  last_seen_at timestamptz not null default now()
);

-- ============================================================
-- 5. TRIGGER : création automatique du profil
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user')
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

insert into public.profiles (id, email, role)
select id, email, 'user'
from auth.users
on conflict (id) do update
  set email = excluded.email,
      updated_at = now();

-- ============================================================
-- 6. FONCTIONS UTILES
-- ============================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select role = 'admin'
      from public.profiles
      where id = auth.uid()
    ),
    false
  );
$$;

-- ============================================================
-- 7. RLS : Enable Row Level Security
-- ============================================================

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.artists enable row level security;
alter table public.artworks enable row level security;
alter table public.forum_discussions enable row level security;
alter table public.trend_tags enable row level security;
alter table public.community_events enable row level security;
alter table public.community_stats enable row level security;

-- Profiles
drop policy if exists "Read own profile" on public.profiles;
create policy "Read own profile" on public.profiles
for select to authenticated
using (auth.uid() = id);

drop policy if exists "Admins read all profiles" on public.profiles;
create policy "Admins read all profiles" on public.profiles
for select to authenticated
using (public.is_admin());

drop policy if exists "Admins update profiles" on public.profiles;
create policy "Admins update profiles" on public.profiles
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Public read for all content tables
drop policy if exists "Public read categories" on public.categories;
create policy "Public read categories" on public.categories for select using (true);

drop policy if exists "Public read artists" on public.artists;
create policy "Public read artists" on public.artists for select using (true);

drop policy if exists "Public read artworks" on public.artworks;
create policy "Public read artworks" on public.artworks for select using (true);

drop policy if exists "Public read forum discussions" on public.forum_discussions;
create policy "Public read forum discussions" on public.forum_discussions for select using (true);

drop policy if exists "Public read trend tags" on public.trend_tags;
create policy "Public read trend tags" on public.trend_tags for select using (true);

drop policy if exists "Public read community events" on public.community_events;
create policy "Public read community events" on public.community_events for select using (true);

drop policy if exists "Public read community stats" on public.community_stats;
create policy "Public read community stats" on public.community_stats for select using (true);

-- Authenticated users can insert their own submissions
drop policy if exists "Users insert artists" on public.artists;
create policy "Users insert artists" on public.artists
for insert to authenticated
with check (public.is_admin() OR true); -- Admins OR any authenticated user can submit

drop policy if exists "Users insert artworks" on public.artworks;
create policy "Users insert artworks" on public.artworks
for insert to authenticated
with check (public.is_admin() OR true);

drop policy if exists "Users insert forum discussions" on public.forum_discussions;
create policy "Users insert forum discussions" on public.forum_discussions
for insert to authenticated
with check (public.is_admin() OR true);

-- Admin-only insert/update
drop policy if exists "Admins insert categories" on public.categories;
create policy "Admins insert categories" on public.categories for insert to authenticated with check (public.is_admin());

drop policy if exists "Admins update categories" on public.categories;
create policy "Admins update categories" on public.categories for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins update artists" on public.artists;
create policy "Admins update artists" on public.artists for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins update artworks" on public.artworks;
create policy "Admins update artworks" on public.artworks for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins update forum discussions" on public.forum_discussions;
create policy "Admins update forum discussions" on public.forum_discussions for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins insert trend tags" on public.trend_tags;
create policy "Admins insert trend tags" on public.trend_tags for insert to authenticated with check (public.is_admin());

drop policy if exists "Admins update trend tags" on public.trend_tags;
create policy "Admins update trend tags" on public.trend_tags for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins insert community events" on public.community_events;
create policy "Admins insert community events" on public.community_events for insert to authenticated with check (public.is_admin());

drop policy if exists "Admins update community events" on public.community_events;
create policy "Admins update community events" on public.community_events for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins insert community stats" on public.community_stats;
create policy "Admins insert community stats" on public.community_stats for insert to authenticated with check (public.is_admin());

drop policy if exists "Admins update community stats" on public.community_stats;
create policy "Admins update community stats" on public.community_stats for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- === CHAT TABLES RLS POLICIES ===

alter table public.chat_channels enable row level security;
alter table public.chat_channel_members enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_groups enable row level security;
alter table public.chat_group_members enable row level security;
alter table public.user_relationships enable row level security;
alter table public.user_presence enable row level security;

-- Channels: public channels readable by anyone, private by members only
drop policy if exists "Public read public channels" on public.chat_channels;
create policy "Public read public channels" on public.chat_channels
for select using (type = 'public');

drop policy if exists "Members read their channels" on public.chat_channels;
create policy "Members read their channels" on public.chat_channels
for select using (
  exists (
    select 1 from public.chat_channel_members
    where channel_id = id and user_id = auth.uid()
  )
);

drop policy if exists "Authenticated users create channels" on public.chat_channels;
create policy "Authenticated users create channels" on public.chat_channels
for insert to authenticated with check (auth.uid() = created_by);

drop policy if exists "Owners and admins update channels" on public.chat_channels;
create policy "Owners and admins update channels" on public.chat_channels
for update to authenticated using (
  exists (
    select 1 from public.chat_channel_members
    where channel_id = id and user_id = auth.uid() and role in ('owner', 'admin')
  )
) with check (
  exists (
    select 1 from public.chat_channel_members
    where channel_id = id and user_id = auth.uid() and role in ('owner', 'admin')
  )
);

-- Channel members: visible to channel members
drop policy if exists "Members read channel members" on public.chat_channel_members;
create policy "Members read channel members" on public.chat_channel_members
for select using (
  exists (
    select 1 from public.chat_channel_members cm
    where cm.channel_id = channel_id and cm.user_id = auth.uid()
  )
);

-- Messages: read if member of channel, write if member
drop policy if exists "Members read messages" on public.chat_messages;
create policy "Members read messages" on public.chat_messages
for select using (
  exists (
    select 1 from public.chat_channel_members
    where channel_id = chat_messages.channel_id and user_id = auth.uid()
  )
);

drop policy if exists "Members insert messages" on public.chat_messages;
create policy "Members insert messages" on public.chat_messages
for insert to authenticated with check (
  auth.uid() = author_id
  and exists (
    select 1 from public.chat_channel_members
    where channel_id = chat_messages.channel_id and user_id = auth.uid()
  )
);

drop policy if exists "Authors update own messages" on public.chat_messages;
create policy "Authors update own messages" on public.chat_messages
for update to authenticated using (auth.uid() = author_id)
with check (auth.uid() = author_id);

-- Groups: created by authenticated users
drop policy if exists "Users read their groups" on public.chat_groups;
create policy "Users read their groups" on public.chat_groups
for select using (
  exists (
    select 1 from public.chat_group_members
    where group_id = id and user_id = auth.uid()
  )
);

drop policy if exists "Users create groups" on public.chat_groups;
create policy "Users create groups" on public.chat_groups
for insert to authenticated with check (auth.uid() = created_by);

-- Group members: visible to group members
drop policy if exists "Group members read members" on public.chat_group_members;
create policy "Group members read members" on public.chat_group_members
for select using (
  exists (
    select 1 from public.chat_group_members gm
    where gm.group_id = chat_group_members.group_id and gm.user_id = auth.uid()
  )
);

-- Friends: visible to both parties
drop policy if exists "Users read their relationships" on public.user_relationships;
create policy "Users read their relationships" on public.user_relationships
for select using (
  auth.uid() = requester_id or auth.uid() = target_id
);

drop policy if exists "Users create relationships" on public.user_relationships;
create policy "Users create relationships" on public.user_relationships
for insert to authenticated with check (auth.uid() = requester_id);

-- Presence: readable by authenticated, writable by self
drop policy if exists "Users read presence" on public.user_presence;
create policy "Users read presence" on public.user_presence
for select to authenticated using (true);

drop policy if exists "Users update own presence" on public.user_presence;
create policy "Users update own presence" on public.user_presence
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users upsert own presence" on public.user_presence;
create policy "Users upsert own presence" on public.user_presence
for update to authenticated using (auth.uid() = user_id)
with check (auth.uid() = user_id);