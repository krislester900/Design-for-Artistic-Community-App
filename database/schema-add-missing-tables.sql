-- ============================================================
-- Artéïa - Ajout des tables manquantes
-- À exécuter si vous avez déjà schema.sql/schema-safe.sql
-- mais que les tables posts, likes, comments, etc. n'existent pas
-- ============================================================

-- ============================================================
-- TABLES DE CONTENU (seulement si elles n'existent pas)
-- ============================================================

-- 1. AMÉLIORATION DE LA TABLE PROFILES (si elle existe)
do $$
begin
  if exists (select 1 from information_schema.tables where table_name = 'profiles') then
    alter table public.profiles add column if not exists username text unique;
    alter table public.profiles add column if not exists avatar_url text;
    alter table public.profiles add column if not exists bio text default '';
    alter table public.profiles add column if not exists followers_count int default 0;
    alter table public.profiles add column if not exists following_count int default 0;
    alter table public.profiles add column if not exists posts_count int default 0;
  end if;
end $$;

-- 2. POSTS (œuvres, publications) - CRÉER SI N'EXISTE PAS
-- Note: category_slug utilise le même type ENUM que categories.slug
-- car schema-safe.sql a créé un type ENUM category_slug
do $$
begin
  if not exists (select 1 from information_schema.tables where table_name = 'posts') then
    create table public.posts (
      id uuid primary key default gen_random_uuid(),
      user_id uuid not null references public.profiles(id) on delete cascade,
      category_slug text,
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
  end if;
end $$;

-- 3. LIKES
create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(post_id, user_id)
);

-- 4. COMMENTS
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5. NOTIFICATIONS
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

-- 6. FOLLOWS (abonnements)
create table if not exists public.follows (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(follower_id, following_id)
);

-- ============================================================
-- FONCTIONNALITÉS AVANCÉES
-- ============================================================

-- 1. AMÉLIORATION DE LA TABLE POSTS
alter table public.posts add column if not exists image_thumbnail_url text;
alter table public.posts add column if not exists image_width int;
alter table public.posts add column if not exists image_height int;
alter table public.posts add column if not exists file_size int;

-- 2. STORAGE BUCKET pour les uploads d'images
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

-- 3. FAVORIS (Artwork Bookmarks)
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

-- 4. FONCTIONS POUR LIKES
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
  update public.posts set likes_count = greatest(0, likes_count - 1) where id = post_id;
end;
$$;

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

-- 7. CATÉGORIES PAR DÉFAUT - IGNORÉ
-- La table categories existe déjà avec ses propres données via schema-safe.sql
-- Les slugs ENUM sont en anglais: 'music', 'visual-art', 'manga', 'film', 'literature', 'animation'
-- Ne pas insérer ici pour éviter les conflits de type ENUM
do $$
begin
  -- Ne rien faire, les catégories existent déjà
end $$;

-- 8. REALTIME (si les tables existent)
do $$
begin
  if exists (select 1 from information_schema.tables where table_name = 'posts') then
    alter publication supabase_realtime add table public.posts;
  end if;
  if exists (select 1 from information_schema.tables where table_name = 'comments') then
    alter publication supabase_realtime add table public.comments;
  end if;
  if exists (select 1 from information_schema.tables where table_name = 'likes') then
    alter publication supabase_realtime add table public.likes;
  end if;
  if exists (select 1 from information_schema.tables where table_name = 'notifications') then
    alter publication supabase_realtime add table public.notifications;
  end if;
  if exists (select 1 from information_schema.tables where table_name = 'follows') then
    alter publication supabase_realtime add table public.follows;
  end if;
end $$;

-- 9. MESSAGE DE SUCCÈS
do $$
begin
  raise notice '✅ Tables manquantes créées avec succès!';
  raise notice '✅ posts, likes, comments, notifications, follows';
  raise notice '✅ favoris, bookmarks, triggers, indexes';
  raise notice '✅ Vous pouvez maintenant utiliser l''application';
end $$;