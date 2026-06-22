-- ============================================================
-- Artéïa - Schema v3: Fonctionnalités manquantes
-- Upload d'images, Likes, Comments, Notifications temps réel,
-- Favoris, Follow/Unfollow, Optimisation
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

-- 2. AMÉLIORATION DE LA TABLE POSTS avec image_url et type d'image
alter table public.posts add column if not exists image_url text;
alter table public.posts add column if not exists image_thumbnail_url text;
alter table public.posts add column if not exists image_width int;
alter table public.posts add column if not exists image_height int;
alter table public.posts add column if not exists file_size int;

-- 3. LIKES - déjà existante, ajout d'une fonction pour compter
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

-- 4. NOTIFICATIONS - amélioration avec type 'follow'
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type in ('like', 'comment', 'follow', 'mention', 'favorite'));

-- Ajout d'index pour les notifications non lues
create index if not exists idx_notifications_unread
  on public.notifications(user_id, read, created_at desc);

-- 5. FOLLOWS - déjà existante, ajout de fonctions trigger
-- Trigger pour mettre à jour les compteurs de followers/following
create or replace function public.handle_follow_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set followers_count = followers_count + 1 where id = new.following_id;
  update public.profiles set following_count = following_count + 1 where id = new.follower_id;
  
  -- Créer une notification pour le follow
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

-- 6. FAVORIS (Artwork Bookmarks) - table déjà existante dans favorites_service
-- S'assurer que la table artwork_favorites existe
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

-- 7. VUE EN LECTURE (Reading history)
create table if not exists public.reading_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  progress float default 0,
  last_read_at timestamptz not null default now(),
  unique(user_id, post_id)
);

alter table public.reading_history enable row level security;

drop policy if exists "Users read own reading history" on public.reading_history;
create policy "Users read own reading history" on public.reading_history
  for select using (auth.uid() = user_id);

drop policy if exists "Users upsert reading history" on public.reading_history;
create policy "Users upsert reading history" on public.reading_history
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users update reading history" on public.reading_history;
create policy "Users update reading history" on public.reading_history
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 8. FONCTION DE RECHERCHE PLEIN TEXTE
alter table public.posts add column if not exists search_vector tsvector
  generated always as (to_tsvector('french', coalesce(title, '') || ' ' || coalesce(description, ''))) stored;

create index if not exists idx_posts_search on public.posts using gin(search_vector);

-- 9. FONCTION POUR OBTENIR LE STATUT DE FOLLOW
create or replace function public.get_follow_status(following_id_param uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case when exists (
    select 1 from public.follows
    where follower_id = auth.uid() and following_id = following_id_param
  ) then 'following' else 'not_following' end;
$$;

-- 10. REALTIME POUR NOTIFICATIONS
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.follows;
alter publication supabase_realtime add table public.artwork_favorites;