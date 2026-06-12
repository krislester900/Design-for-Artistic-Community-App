-- ============================================================
-- Artéïa - Database Schema v2
-- Améliorations : likes, comments, views, notifications,
-- uploads tracking, favoris, signalements
-- ============================================================

-- Amendments to existing tables
alter table public.artists
  add column if not exists bio text not null default '',
  add column if not exists cover_image text,
  add column if not exists social_links jsonb not null default '{}',
  add column if not exists is_featured boolean not null default false,
  add column if not exists updated_at timestamptz not null default now();

alter table public.artworks
  add column if not exists description text not null default '',
  add column if not exists tags text[] not null default '{}',
  add column if not exists is_featured boolean not null default false,
  add column if not exists updated_at timestamptz not null default now();

-- ============================================================
-- 1. USER FAVORITES (bookmarks)
-- ============================================================

create table if not exists public.user_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('artist', 'artwork', 'discussion')),
  target_id uuid not null,
  created_at timestamptz not null default now(),
  unique (user_id, target_type, target_id)
);

-- ============================================================
-- 2. COMMENTS on artworks/discussions
-- ============================================================

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('artwork', 'discussion', 'artist')),
  target_id uuid not null,
  content text not null,
  parent_id uuid references public.comments(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 3. NOTIFICATIONS
-- ============================================================

create type public.notification_type as enum (
  'like',
  'comment',
  'follow',
  'favorite',
  'mention',
  'system'
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  type public.notification_type not null,
  title text not null,
  body text not null default '',
  link text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_unread
  on public.notifications (user_id, is_read, created_at desc);

-- ============================================================
-- 4. ARTWORK VIEWS (analytics)
-- ============================================================

create table if not exists public.artwork_views (
  id uuid primary key default gen_random_uuid(),
  artwork_id uuid not null references public.artworks(id) on delete cascade,
  viewer_id uuid references public.profiles(id) on delete set null,
  viewed_at timestamptz not null default now()
);

create index if not exists idx_artwork_views_count
  on public.artwork_views (artwork_id, viewed_at);

-- ============================================================
-- 5. REPORTS (signaler contenu abusif)
-- ============================================================

create type public.report_reason as enum (
  'spam',
  'harassment',
  'inappropriate',
  'copyright',
  'other'
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('artwork', 'discussion', 'artist', 'comment', 'message')),
  target_id uuid not null,
  reason public.report_reason not null,
  description text not null default '',
  is_resolved boolean not null default false,
  resolved_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- ============================================================
-- 6. UPLOADS TRACKING
-- ============================================================

create table if not exists public.user_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  file_name text not null,
  file_size bigint not null,
  mime_type text not null,
  storage_path text not null,
  target_type text check (target_type in ('artwork', 'artist', 'avatar', 'attachment')),
  target_id uuid,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 7. FOLLOW SYSTEM
-- ============================================================

create table if not exists public.user_follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint cannot_follow_self check (follower_id <> following_id)
);

-- ============================================================
-- 8. TAGS SYSTEM (for artworks)
-- ============================================================

create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 9. RLS POLICIES FOR NEW TABLES
-- ============================================================

alter table public.user_favorites enable row level security;
alter table public.comments enable row level security;
alter table public.notifications enable row level security;
alter table public.artwork_views enable row level security;
alter table public.reports enable row level security;
alter table public.user_uploads enable row level security;
alter table public.user_follows enable row level security;
alter table public.tags enable row level security;

-- Favorites: users manage their own
drop policy if exists "Users manage their favorites" on public.user_favorites;
create policy "Users manage their favorites" on public.user_favorites
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Comments: readable by all, writable by authenticated
drop policy if exists "Public read comments" on public.comments;
create policy "Public read comments" on public.comments for select using (true);

drop policy if exists "Auth insert comments" on public.comments;
create policy "Auth insert comments" on public.comments
  for insert to authenticated with check (auth.uid() = author_id);

drop policy if exists "Authors update comments" on public.comments;
create policy "Authors update comments" on public.comments
  for update to authenticated using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

-- Notifications: only the owner can read/update
drop policy if exists "Users read their notifications" on public.notifications;
create policy "Users read their notifications" on public.notifications
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users update their notifications" on public.notifications;
create policy "Users update their notifications" on public.notifications
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Artwork views: insert by authenticated, readable by all
drop policy if exists "Public read artwork views" on public.artwork_views;
create policy "Public read artwork views" on public.artwork_views for select using (true);

drop policy if exists "Auth insert artwork views" on public.artwork_views;
create policy "Auth insert artwork views" on public.artwork_views
  for insert to authenticated with check (true);

-- Reports: users insert, admins manage
drop policy if exists "Users insert reports" on public.reports;
create policy "Users insert reports" on public.reports
  for insert to authenticated with check (auth.uid() = reporter_id);

drop policy if exists "Admins manage reports" on public.reports;
create policy "Admins manage reports" on public.reports
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Uploads: users manage their own
drop policy if exists "Users manage their uploads" on public.user_uploads;
create policy "Users manage their uploads" on public.user_uploads
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Follows: users manage their own
drop policy if exists "Users manage follows" on public.user_follows;
create policy "Users manage follows" on public.user_follows
  for all to authenticated
  using (auth.uid() = follower_id)
  with check (auth.uid() = follower_id);

-- Follows: readable by authenticated
drop policy if exists "Auth read follows" on public.user_follows;
create policy "Auth read follows" on public.user_follows
  for select to authenticated using (true);

-- Tags: public read, admin write
drop policy if exists "Public read tags" on public.tags;
create policy "Public read tags" on public.tags for select using (true);

drop policy if exists "Admins manage tags" on public.tags;
create policy "Admins manage tags" on public.tags
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());