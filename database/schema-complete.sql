-- ============================================================
-- Artéïa - Schema complet (toutes les fonctionnalités)
-- Exécutez CE fichier dans Supabase SQL Editor
-- ============================================================

-- ============================================================
-- PARTIE 1: SCHEMA DE BASE (schema.sql)
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

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role public.app_role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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
-- PARTIE 2: SCHEMA DE CONTENU (schema-content.sql)
-- ============================================================

-- Amélioration de la table profiles
alter table public.profiles add column if not exists username text unique;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists bio text default '';
alter table public.profiles add column if not exists followers_count int default 0;
alter table public.profiles add column if not exists following_count int default 0;
alter table public.profiles add column if not exists posts_count int default 0;

-- 3. POSTS (œuvres, publications)
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_slug text not null references public.categories(slug) on delete restrict,
  title text not null,
  description text default '',
  image_url text,
  type text not null check (type in ('art', 'music', 'manga', 'film', 'literature', 'animation')),
  likes_count int default 0,
  comments_count int default 0,
  views_count int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. LIKES
create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(post_id, user_id)
);

-- 5. COMMENTS
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 6. NOTIFICATIONS
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('like', 'comment', 'follow', 'mention', 'favorite')),
  from_user_id uuid references public.profiles(id) on delete set null,
  post_id uuid references public.posts(id) on delete cascade,
  message text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

-- 7. FOLLOWS (abonnements)
create table if not exists public.follows (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(follower_id, following_id)
);

-- ============================================================
-- PARTIE 3: FONCTIONNALITÉS AVANCÉES (schema-v3-features.sql)
-- ============================================================

-- 1. STORAGE BUCKET pour les uploads d'images
insert into storage.buckets (id, name, public) values ('artworks', 'artworks', true)
on conflict (id) do nothing;

-- Storage RLS policies
drop policy if exists "Public read artworks" on storage.objects;
create policy "Public read artworks" on storage.objects
  for select using (bucket_id = 'artworks');

drop policy if exists "Auth upload artworks" on storage.objects;
create policy "Auth upload artworks" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'artworks' and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners update artworks" on storage.objects;
create policy "Owners update artworks" on storage.objects
  for update to authenticated using (
    bucket_id = 'artworks' and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners delete artworks" on storage.objects;
create policy "Owners delete artworks" on storage.objects
  for delete to authenticated using (
    bucket_id = 'artworks' and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 2. AMÉLIORATION DE LA TABLE POSTS
alter table public.posts add column if not exists image_thumbnail_url text;
alter table public.posts add column if not exists image_width int;
alter table public.posts add column if not exists image_height int;
alter table public.posts add column if not exists file_size int;

-- 3. FONCTIONS POUR LIKES
create or replace function public.increment_post_likes(post_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.posts set likes_count = likes_count + 1 where id = post_id;
end;
$$;

create or replace function public.decrement_post_likes(post_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.posts set greatest(0, likes_count - 1) where id = post_id;
end;
$$;

-- 4. FAVORIS (Artwork Bookmarks)
create table if not exists public.artwork_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  artwork_id uuid not null references public.artworks(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, artwork_id)
);

create table if not exists public.artwork_bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  artwork_id uuid not null references public.artworks(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, artwork_id)
);

-- RLS pour favorites/bookmarks
alter table public.artwork_favorites enable row level security;
alter table public.artwork_bookmarks enable row level security;

drop policy if exists "Users read own favorites" on public.artwork_favorites;
create policy "Users read own favorites" on public.artwork_favorites
  for select using (auth.uid() = user_id);

drop policy if exists "Auth insert favorites" on public.artwork_favorites;
create policy "Auth insert favorites" on public.artwork_favorites
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Auth delete favorites" on public.artwork_favorites;
create policy "Auth delete favorites" on public.artwork_favorites
  for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "Users read own bookmarks" on public.artwork_bookmarks;
create policy "Users read own bookmarks" on public.artwork_bookmarks
  for select using (auth.uid() = user_id);

drop policy if exists "Auth insert bookmarks" on public.artwork_bookmarks;
create policy "Auth insert bookmarks" on public.artwork_bookmarks
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Auth delete bookmarks" on public.artwork_bookmarks;
create policy "Auth delete bookmarks" on public.artwork_bookmarks
  for delete to authenticated using (auth.uid() = user_id);

-- 5. TRIGGERS POUR FOLLOWS
create or replace function public.handle_follow_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set followers_count = followers_count + 1 where id = new.following_id;
  update public.profiles set following_count = following_count + 1 where id = new.follower_id;
  
  insert into public.notifications (user_id, type, from_user_id, message)
  values (new.following_id, 'follow', new.follower_id, 'a commencé à vous suivre');
  
  return new;
end;
$$;

create or replace function public.handle_follow_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set followers_count = greatest(0, followers_count - 1) where id = old.following_id;
  update public.profiles set following_count = greatest(0, following_count - 1) where id = old.follower_id;
  return old;
end;
$$;

drop trigger if exists on_follow_insert on public.follows;
create trigger on_follow_insert
  after insert on public.follows
  for each row execute procedure public.handle_follow_insert();

drop trigger if exists on_follow_delete on public.follows;
create trigger on_follow_delete
  after delete on public.follows
  for each row execute procedure public.handle_follow_delete();

-- 6. INDEXES
create index if not exists idx_posts_category on public.posts(category_slug);
create index if not exists idx_posts_user on public.posts(user_id);
create index if not exists idx_posts_created on public.posts(created_at desc);
create index if not exists idx_likes_post on public.likes(post_id);
create index if not exists idx_comments_post on public.comments(post_id);
create index if not exists idx_notifications_user on public.notifications(user_id, read, created_at desc);

-- 7. CATÉGORIES PAR DÉFAUT
insert into public.categories (slug, name, description, icon, color) values
  ('musique', 'Musique', 'Partagez vos créations musicales', '🎵', '#7C5CFC'),
  ('art-visuel', 'Arts Visuels', 'Galerie et discussions artistiques', '🎨', '#00D4AA'),
  ('litterature', 'Littérature', 'Poèmes, histoires et écrits', '✍️', '#FF6B9D'),
  ('manga', 'Manga', 'Mangas et illustrations japonaises', '📚', '#FFA500'),
  ('films', 'Films', 'Cinéma et productions vidéo', '🎬', '#00BFFF'),
  ('animation', 'Animation', 'Animations et motion design', '🎞️', '#FF69B4')
on conflict do nothing;

-- ============================================================
-- PARTIE 4: RLS POLICIES
-- ============================================================

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.artists enable row level security;
alter table public.artworks enable row level security;
alter table public.forum_discussions enable row level security;
alter table public.trend_tags enable row level security;
alter table public.community_events enable row level security;
alter table public.community_stats enable row level security;
alter table public.posts enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.notifications enable row level security;
alter table public.follows enable row level security;

-- Profiles
drop policy if exists "Public read profiles" on public.profiles;
create policy "Public read profiles" on public.profiles for select using (true);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles
  for update to authenticated using (auth.uid() = id)
  with check (auth.uid() = id);

-- Categories
drop policy if exists "Public read categories" on public.categories;
create policy "Public read categories" on public.categories for select using (true);

-- Artists
drop policy if exists "Public read artists" on public.artists;
create policy "Public read artists" on public.artists for select using (true);

-- Artworks
drop policy if exists "Public read artworks" on public.artworks;
create policy "Public read artworks" on public.artworks for select using (true);

-- Forum discussions
drop policy if exists "Public read forum discussions" on public.forum_discussions;
create policy "Public read forum discussions" on public.forum_discussions for select using (true);

-- Trend tags
drop policy if exists "Public read trend tags" on public.trend_tags;
create policy "Public read trend tags" on public.trend_tags for select using (true);

-- Community events
drop policy if exists "Public read community events" on public.community_events;
create policy "Public read community events" on public.community_events for select using (true);

-- Community stats
drop policy if exists "Public read community stats" on public.community_stats;
create policy "Public read community stats" on public.community_stats for select using (true);

-- Posts
drop policy if exists "Public read posts" on public.posts;
create policy "Public read posts" on public.posts for select using (true);

drop policy if exists "Auth create posts" on public.posts;
create policy "Auth create posts" on public.posts
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users update own posts" on public.posts;
create policy "Users update own posts" on public.posts
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users delete own posts" on public.posts;
create policy "Users delete own posts" on public.posts
  for delete to authenticated using (auth.uid() = user_id);

-- Likes
drop policy if exists "Public read likes" on public.likes;
create policy "Public read likes" on public.likes for select using (true);

drop policy if exists "Auth insert likes" on public.likes;
create policy "Auth insert likes" on public.likes
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Auth delete likes" on public.likes;
create policy "Auth delete likes" on public.likes
  for delete to authenticated using (auth.uid() = user_id);

-- Comments
drop policy if exists "Public read comments" on public.comments;
create policy "Public read comments" on public.comments for select using (true);

drop policy if exists "Auth insert comments" on public.comments;
create policy "Auth insert comments" on public.comments
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users update own comments" on public.comments;
create policy "Users update own comments" on public.comments
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Notifications
drop policy if exists "Users read own notifications" on public.notifications;
create policy "Users read own notifications" on public.notifications
  for select using (auth.uid() = user_id);

drop policy if exists "System insert notifications" on public.notifications;
create policy "System insert notifications" on public.notifications
  for insert with check (true);

drop policy if exists "Users update own notifications" on public.notifications;
create policy "Users update own notifications" on public.notifications
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Follows
drop policy if exists "Public read follows" on public.follows;
create policy "Public read follows" on public.follows for select using (true);

drop policy if exists "Auth insert follows" on public.follows;
create policy "Auth insert follows" on public.follows
  for insert to authenticated with check (auth.uid() = follower_id);

drop policy if exists "Auth delete follows" on public.follows;
create policy "Auth delete follows" on public.follows
  for delete to authenticated using (auth.uid() = follower_id);

-- ============================================================
-- PARTIE 5: TRIGGERS ET FONCTIONS
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
-- PARTIE 6: REALTIME
-- ============================================================

alter publication supabase_realtime add table public.posts;
alter publication supabase_realtime add table public.comments;
alter publication supabase_realtime add table public.likes;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.follows;