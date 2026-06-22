-- ============================================================
-- Artéïa - Tables de contenu (posts, catégories, profiles)
-- ============================================================

-- 1. PROFILS UTILISATEURS
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  avatar_url text,
  bio text default '',
  role text default 'artist',
  followers_count int default 0,
  following_count int default 0,
  posts_count int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. CATÉGORIES
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text default '',
  icon text default '📝',
  color text default '#7C5CFC',
  created_at timestamptz not null default now()
);

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
  type text not null check (type in ('like', 'comment', 'follow', 'mention')),
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
-- INDEXES
-- ============================================================
create index if not exists idx_posts_category on public.posts(category_slug);
create index if not exists idx_posts_user on public.posts(user_id);
create index if not exists idx_posts_created on public.posts(created_at desc);
create index if not exists idx_likes_post on public.likes(post_id);
create index if not exists idx_comments_post on public.comments(post_id);
create index if not exists idx_notifications_user on public.notifications(user_id, read, created_at desc);

-- ============================================================
-- CATÉGORIES PAR DÉFAUT
-- ============================================================
insert into public.categories (slug, name, description, icon, color) values
  ('musique', 'Musique', 'Partagez vos créations musicales', '🎵', '#7C5CFC'),
  ('art-visuel', 'Arts Visuels', 'Galerie et discussions artistiques', '🎨', '#00D4AA'),
  ('litterature', 'Littérature', 'Poèmes, histoires et écrits', '✍️', '#FF6B9D'),
  ('manga', 'Manga', 'Mangas et illustrations japonaises', '📚', '#FFA500'),
  ('films', 'Films', 'Cinéma et productions vidéo', '🎬', '#00BFFF'),
  ('animation', 'Animation', 'Animations et motion design', '🎞️', '#FF69B4')
on conflict do nothing;

-- ============================================================
-- REALTIME
-- ============================================================
alter publication supabase_realtime add table public.posts;
alter publication supabase_realtime add table public.comments;
alter publication supabase_realtime add table public.likes;
alter publication supabase_realtime add table public.notifications;

-- ============================================================
-- RLS POLICIES
-- ============================================================
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.posts enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.notifications enable row level security;
alter table public.follows enable row level security;

-- Profiles : tout le monde peut lire, utilisateur peut modifier le sien
drop policy if exists "Public read profiles" on public.profiles;
create policy "Public read profiles" on public.profiles for select using (true);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles
  for update to authenticated using (auth.uid() = id)
  with check (auth.uid() = id);

-- Categories : tout le monde peut lire
drop policy if exists "Public read categories" on public.categories;
create policy "Public read categories" on public.categories for select using (true);

-- Posts : tout le monde peut lire, utilisateurs connectés peuvent créer
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

-- Likes : tout le monde peut lire, utilisateurs connectés peuvent liker
drop policy if exists "Public read likes" on public.likes;
create policy "Public read likes" on public.likes for select using (true);

drop policy if exists "Auth insert likes" on public.likes;
create policy "Auth insert likes" on public.likes
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Auth delete likes" on public.likes;
create policy "Auth delete likes" on public.likes
  for delete to authenticated using (auth.uid() = user_id);

-- Comments : tout le monde peut lire, utilisateurs connectés peuvent commenter
drop policy if exists "Public read comments" on public.comments;
create policy "Public read comments" on public.comments for select using (true);

drop policy if exists "Auth insert comments" on public.comments;
create policy "Auth insert comments" on public.comments
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users update own comments" on public.comments;
create policy "Users update own comments" on public.comments
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Notifications : utilisateur peut voir ses propres notifications
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

-- Follows : tout le monde peut lire
drop policy if exists "Public read follows" on public.follows;
create policy "Public read follows" on public.follows for select using (true);

drop policy if exists "Auth insert follows" on public.follows;
create policy "Auth insert follows" on public.follows
  for insert to authenticated with check (auth.uid() = follower_id);

drop policy if exists "Auth delete follows" on public.follows;
create policy "Auth delete follows" on public.follows
  for delete to authenticated using (auth.uid() = follower_id);