-- ============================================================
-- ARTÉÏA — Script adapté au schéma existant
-- La table categories utilise "title" et non "name"
-- 
-- ⚠️ EXÉCUTION EN DEUX TEMPS ⚠️
-- ÉTAPE 1 : Exécutez d'abord la section 0 (ALTER TYPE) seule
-- ÉTAPE 2 : Puis exécutez le reste du fichier (sections 1-9)
-- ============================================================

create extension if not exists "uuid-ossp";

-- ============================================================
-- ÉTAPE 1 - À EXÉCUTER SEULE D'ABORD
-- ============================================================
do $$ begin
  if not exists (select 1 from pg_enum where enumlabel = 'illustration' and enumtypid = 'public.category_slug'::regtype) then
    alter type public.category_slug add value 'illustration';
  end if;
  if not exists (select 1 from pg_enum where enumlabel = 'writing' and enumtypid = 'public.category_slug'::regtype) then
    alter type public.category_slug add value 'writing';
  end if;
  if not exists (select 1 from pg_enum where enumlabel = 'photo' and enumtypid = 'public.category_slug'::regtype) then
    alter type public.category_slug add value 'photo';
  end if;
  if not exists (select 1 from pg_enum where enumlabel = '3d' and enumtypid = 'public.category_slug'::regtype) then
    alter type public.category_slug add value '3d';
  end if;
end $$;

-- ⛔ STOP : Exécutez d'abord uniquement ce bloc ci-dessus,
--    puis exécutez le reste du fichier (sections 1-9 ci-dessous)
-- ============================================================

-- ============================================================
-- 1. PROFILS
-- ============================================================
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  username        text unique,
  display_name    text,
  avatar_url      text,
  bio             text,
  website         text,
  role            text default 'user',
  followers_count int default 0,
  following_count int default 0,
  artworks_count  int default 0,
  is_verified     boolean default false,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

alter table public.profiles add column if not exists username text;
alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists website text;
alter table public.profiles add column if not exists role text default 'user';
alter table public.profiles add column if not exists followers_count int default 0;
alter table public.profiles add column if not exists following_count int default 0;
alter table public.profiles add column if not exists artworks_count int default 0;
alter table public.profiles add column if not exists is_verified boolean default false;
alter table public.profiles add column if not exists updated_at timestamptz default now();

alter table public.profiles enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='profiles' and policyname='Profil visible par tous') then
    create policy "Profil visible par tous" on public.profiles for select using (true);
  end if;
  if not exists (select 1 from pg_policies where tablename='profiles' and policyname='Modifier son propre profil') then
    create policy "Modifier son propre profil" on public.profiles for update using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where tablename='profiles' and policyname='Insérer son propre profil') then
    create policy "Insérer son propre profil" on public.profiles for insert with check (auth.uid() = id);
  end if;
end $$;

-- Trigger création automatique du profil
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ============================================================
-- 2. CATÉGORIES
-- ============================================================
-- Insertion safe : les valeurs d'enum ont été ajoutées à l'étape 1
insert into public.categories (title, slug, color, sort_order) values
  ('Illustration',  'illustration', '#7C5CFC', 1),
  ('Musique',       'music',        '#14B8A6', 2),
  ('Écriture',      'writing',      '#F472B6', 3),
  ('BD & Manga',    'manga',        '#FB923C', 4),
  ('Photographie',  'photo',        '#60A5FA', 5),
  ('3D & Design',   '3d',           '#A78BFA', 6)
on conflict (slug) do nothing;


-- ============================================================
-- 3. ŒUVRES / ARTWORKS
-- ============================================================
create table if not exists public.artworks (
  id              uuid primary key default uuid_generate_v4(),
  author_id       uuid not null references public.profiles(id) on delete cascade,
  title           text not null,
  description     text,
  image_url       text,
  audio_url       text,
  category_slug   text,
  tags            text[],
  likes_count     int default 0,
  views_count     int default 0,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

alter table public.artworks enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='artworks' and policyname='Œuvres visibles par tous') then
    create policy "Œuvres visibles par tous" on public.artworks for select using (true);
  end if;
  if not exists (select 1 from pg_policies where tablename='artworks' and policyname='Créer son œuvre') then
    create policy "Créer son œuvre" on public.artworks for insert with check (auth.uid() = author_id);
  end if;
  if not exists (select 1 from pg_policies where tablename='artworks' and policyname='Modifier/supprimer son œuvre') then
    create policy "Modifier/supprimer son œuvre" on public.artworks for all using (auth.uid() = author_id);
  end if;
end $$;


-- ============================================================
-- 4. LIKES
-- ============================================================
create table if not exists public.likes (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  artwork_id  uuid not null references public.artworks(id) on delete cascade,
  created_at  timestamptz default now(),
  unique(user_id, artwork_id)
);

alter table public.likes enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='likes' and policyname='Likes visibles par tous') then
    create policy "Likes visibles par tous" on public.likes for select using (true);
  end if;
  if not exists (select 1 from pg_policies where tablename='likes' and policyname='Liker si connecté') then
    create policy "Liker si connecté" on public.likes for insert with check (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where tablename='likes' and policyname='Unliker le sien') then
    create policy "Unliker le sien" on public.likes for delete using (auth.uid() = user_id);
  end if;
end $$;

create or replace function public.update_likes_count()
returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    update public.artworks set likes_count = likes_count + 1 where id = new.artwork_id;
  elsif (tg_op = 'DELETE') then
    update public.artworks set likes_count = greatest(0, likes_count - 1) where id = old.artwork_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_like_change on public.likes;
create trigger on_like_change
  after insert or delete on public.likes
  for each row execute procedure public.update_likes_count();


-- ============================================================
-- 5. COMMENTAIRES
-- ============================================================
create table if not exists public.comments (
  id          uuid primary key default uuid_generate_v4(),
  artwork_id  uuid not null references public.artworks(id) on delete cascade,
  author_id   uuid not null references public.profiles(id) on delete cascade,
  content     text not null,
  likes_count int default 0,
  created_at  timestamptz default now()
);

alter table public.comments enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='comments' and policyname='Commentaires visibles par tous') then
    create policy "Commentaires visibles par tous" on public.comments for select using (true);
  end if;
  if not exists (select 1 from pg_policies where tablename='comments' and policyname='Commenter si connecté') then
    create policy "Commenter si connecté" on public.comments for insert with check (auth.uid() = author_id);
  end if;
  if not exists (select 1 from pg_policies where tablename='comments' and policyname='Supprimer son commentaire') then
    create policy "Supprimer son commentaire" on public.comments for delete using (auth.uid() = author_id);
  end if;
end $$;

create or replace function public.update_comments_count()
returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    update public.artworks set comments_count = coalesce(comments_count, 0) + 1 where id = new.artwork_id;
  elsif (tg_op = 'DELETE') then
    update public.artworks set comments_count = greatest(0, coalesce(comments_count, 0) - 1) where id = old.artwork_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_comment_change on public.comments;
create trigger on_comment_change
  after insert or delete on public.comments
  for each row execute procedure public.update_comments_count();


-- ============================================================
-- 6. FOLLOWS
-- ============================================================
create table if not exists public.follows (
  follower_id  uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at   timestamptz default now(),
  primary key (follower_id, following_id),
  constraint no_self_follow check (follower_id <> following_id)
);

alter table public.follows enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='follows' and policyname='Follows visibles par tous') then
    create policy "Follows visibles par tous" on public.follows for select using (true);
  end if;
  if not exists (select 1 from pg_policies where tablename='follows' and policyname='Follow si connecté') then
    create policy "Follow si connecté" on public.follows for insert with check (auth.uid() = follower_id);
  end if;
  if not exists (select 1 from pg_policies where tablename='follows' and policyname='Unfollow le sien') then
    create policy "Unfollow le sien" on public.follows for delete using (auth.uid() = follower_id);
  end if;
end $$;

-- Trigger pour compter les followers/following
create or replace function public.update_follow_counts()
returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    update public.profiles set followers_count = followers_count + 1 where id = new.following_id;
    update public.profiles set following_count = following_count + 1 where id = new.follower_id;
  elsif (tg_op = 'DELETE') then
    update public.profiles set followers_count = greatest(0, followers_count - 1) where id = old.following_id;
    update public.profiles set following_count = greatest(0, following_count - 1) where id = old.follower_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_follow_change on public.follows;
create trigger on_follow_change
  after insert or delete on public.follows
  for each row execute procedure public.update_follow_counts();


-- ============================================================
-- 7. FAVORIS
-- ============================================================
create table if not exists public.favorites (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  artwork_id uuid not null references public.artworks(id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, artwork_id)
);

alter table public.favorites enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='favorites' and policyname='Favoris visibles par le propriétaire') then
    create policy "Favoris visibles par le propriétaire" on public.favorites for select using (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where tablename='favorites' and policyname='Ajouter aux favoris') then
    create policy "Ajouter aux favoris" on public.favorites for insert with check (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where tablename='favorites' and policyname='Retirer des favoris') then
    create policy "Retirer des favoris" on public.favorites for delete using (auth.uid() = user_id);
  end if;
end $$;


-- ============================================================
-- 8. NOTIFICATIONS
-- ============================================================
create table if not exists public.notifications (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  type       text not null,
  title      text not null,
  data       jsonb default '{}',
  is_read    boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_notifications_user on notifications(user_id, created_at desc);

alter table public.notifications enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='notifications' and policyname='Notifications visibles par le propriétaire') then
    create policy "Notifications visibles par le propriétaire" on public.notifications for select using (auth.uid() = user_id);
  end if;
end $$;


-- ============================================================
-- 9. SIGNALEMENTS / REPORT
-- ============================================================
create table if not exists public.reports (
  id             uuid primary key default uuid_generate_v4(),
  reporter_id    uuid not null references public.profiles(id) on delete cascade,
  target_type    text not null,
  target_id      uuid not null,
  reason         text not null,
  description    text,
  status         text default 'pending',
  resolved_by    uuid references public.profiles(id),
  created_at     timestamptz default now(),
  resolved_at    timestamptz
);

alter table public.reports enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='reports' and policyname='Signaler si connecté') then
    create policy "Signaler si connecté" on public.reports for insert with check (auth.uid() = reporter_id);
  end if;
end $$;