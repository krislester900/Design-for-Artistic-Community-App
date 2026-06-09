-- Supabase / PostgreSQL schema for Artistic Community App
-- Run this file in the Supabase SQL editor.
-- This schema creates an empty pre-launch database.

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

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role public.app_role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.artists enable row level security;
alter table public.artworks enable row level security;
alter table public.forum_discussions enable row level security;
alter table public.trend_tags enable row level security;
alter table public.community_events enable row level security;
alter table public.community_stats enable row level security;

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

drop policy if exists "Admins insert categories" on public.categories;
create policy "Admins insert categories" on public.categories for insert to authenticated with check (public.is_admin());

drop policy if exists "Admins update categories" on public.categories;
create policy "Admins update categories" on public.categories for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins insert artists" on public.artists;
create policy "Admins insert artists" on public.artists for insert to authenticated with check (public.is_admin());

drop policy if exists "Admins update artists" on public.artists;
create policy "Admins update artists" on public.artists for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins insert artworks" on public.artworks;
create policy "Admins insert artworks" on public.artworks for insert to authenticated with check (public.is_admin());

drop policy if exists "Admins update artworks" on public.artworks;
create policy "Admins update artworks" on public.artworks for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins insert forum discussions" on public.forum_discussions;
create policy "Admins insert forum discussions" on public.forum_discussions for insert to authenticated with check (public.is_admin());

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

-- No seed data is inserted here on purpose.
-- The application keeps its visual sections locally and starts with empty content.
