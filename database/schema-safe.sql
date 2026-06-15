-- Safe version: ignores existing types/tables
-- Run this in Supabase SQL Editor

create extension if not exists pgcrypto;

-- Create types only if they don't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'category_slug') THEN
    CREATE TYPE public.category_slug AS ENUM ('music','visual-art','manga','film','literature','animation');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'section_id') THEN
    CREATE TYPE public.section_id AS ENUM ('artists','showcase','forum');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
    CREATE TYPE public.app_role AS ENUM ('user','admin');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'channel_type') THEN
    CREATE TYPE public.channel_type AS ENUM ('public','private','dm');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'member_role') THEN
    CREATE TYPE public.member_role AS ENUM ('owner','admin','member');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'relationship_status') THEN
    CREATE TYPE public.relationship_status AS ENUM ('pending','accepted','blocked');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_presence_status') THEN
    CREATE TYPE public.user_presence_status AS ENUM ('online','idle','offline');
  END IF;
END $$;

-- Tables
CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug public.category_slug UNIQUE NOT NULL,
  title text NOT NULL,
  short_label text NOT NULL,
  description text NOT NULL,
  image text NOT NULL,
  color text NOT NULL,
  target_section_id public.section_id NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  role public.app_role NOT NULL DEFAULT 'user',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.artists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category_slug public.category_slug NOT NULL REFERENCES public.categories(slug) ON DELETE RESTRICT,
  role text NOT NULL,
  image text NOT NULL,
  featured_work text NOT NULL,
  likes integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.artworks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  artist_name text NOT NULL,
  category_slug public.category_slug NOT NULL REFERENCES public.categories(slug) ON DELETE RESTRICT,
  medium text NOT NULL,
  image text NOT NULL,
  likes integer NOT NULL DEFAULT 0,
  views integer NOT NULL DEFAULT 0,
  height text NOT NULL DEFAULT 'aspect-square',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.forum_discussions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  author_name text NOT NULL,
  category_slug public.category_slug NOT NULL REFERENCES public.categories(slug) ON DELETE RESTRICT,
  replies integer NOT NULL DEFAULT 0,
  time_label text NOT NULL,
  trending boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.trend_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tag text NOT NULL UNIQUE,
  count_label text NOT NULL DEFAULT '0',
  category_slug public.category_slug NOT NULL REFERENCES public.categories(slug) ON DELETE RESTRICT,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.community_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  date_label text NOT NULL,
  category_slug public.category_slug NOT NULL REFERENCES public.categories(slug) ON DELETE RESTRICT,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.community_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  number_label text NOT NULL DEFAULT '0',
  label text NOT NULL UNIQUE,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type public.channel_type NOT NULL DEFAULT 'public',
  category_slug public.category_slug REFERENCES public.categories(slug) ON DELETE SET NULL,
  description text NOT NULL DEFAULT '',
  background_image text,
  created_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_locked boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_channel_members (
  channel_id uuid NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role public.member_role NOT NULL DEFAULT 'member',
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (channel_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id uuid NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  reply_to uuid REFERENCES public.chat_messages(id) ON DELETE SET NULL,
  attachment_url text,
  edited_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  image text,
  created_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  max_members integer NOT NULL DEFAULT 10000,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_group_members (
  group_id uuid NOT NULL REFERENCES public.chat_groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role public.member_role NOT NULL DEFAULT 'member',
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.user_relationships (
  requester_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  target_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.relationship_status NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (requester_id, target_id),
  CONSTRAINT different_users CHECK (requester_id <> target_id)
);

CREATE TABLE IF NOT EXISTS public.user_presence (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.user_presence_status NOT NULL DEFAULT 'offline',
  last_seen_at timestamptz NOT NULL DEFAULT now()
);

-- Trigger: auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user')
  ON CONFLICT (id) DO UPDATE
    SET email = excluded.email,
        updated_at = now();
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Insert existing users into profiles
INSERT INTO public.profiles (id, email, role)
SELECT id, email, 'user'
FROM auth.users
ON CONFLICT (id) DO UPDATE
  SET email = excluded.email,
      updated_at = now();

-- Admin function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(
    (SELECT role = 'admin' FROM public.profiles WHERE id = auth.uid()),
    false
  );
$$;

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trend_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_channel_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_presence ENABLE ROW LEVEL SECURITY;

-- Profiles policies
DROP POLICY IF EXISTS "Read own profile" ON public.profiles;
CREATE POLICY "Read own profile" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins read all profiles" ON public.profiles;
CREATE POLICY "Admins read all profiles" ON public.profiles FOR SELECT TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "Admins update profiles" ON public.profiles;
CREATE POLICY "Admins update profiles" ON public.profiles FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Public read for content tables
DROP POLICY IF EXISTS "Public read categories" ON public.categories;
CREATE POLICY "Public read categories" ON public.categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read artists" ON public.artists;
CREATE POLICY "Public read artists" ON public.artists FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read artworks" ON public.artworks;
CREATE POLICY "Public read artworks" ON public.artworks FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read forum discussions" ON public.forum_discussions;
CREATE POLICY "Public read forum discussions" ON public.forum_discussions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read trend tags" ON public.trend_tags;
CREATE POLICY "Public read trend tags" ON public.trend_tags FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read community events" ON public.community_events;
CREATE POLICY "Public read community events" ON public.community_events FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read community stats" ON public.community_stats;
CREATE POLICY "Public read community stats" ON public.community_stats FOR SELECT USING (true);

-- Authenticated insert policies
DROP POLICY IF EXISTS "Users insert artists" ON public.artists;
CREATE POLICY "Users insert artists" ON public.artists FOR INSERT TO authenticated WITH CHECK (public.is_admin() OR true);

DROP POLICY IF EXISTS "Users insert artworks" ON public.artworks;
CREATE POLICY "Users insert artworks" ON public.artworks FOR INSERT TO authenticated WITH CHECK (public.is_admin() OR true);

DROP POLICY IF EXISTS "Users insert forum discussions" ON public.forum_discussions;
CREATE POLICY "Users insert forum discussions" ON public.forum_discussions FOR INSERT TO authenticated WITH CHECK (public.is_admin() OR true);

-- Admin-only policies
DROP POLICY IF EXISTS "Admins insert categories" ON public.categories;
CREATE POLICY "Admins insert categories" ON public.categories FOR INSERT TO authenticated WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins update categories" ON public.categories;
CREATE POLICY "Admins update categories" ON public.categories FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins update artists" ON public.artists;
CREATE POLICY "Admins update artists" ON public.artists FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins update artworks" ON public.artworks;
CREATE POLICY "Admins update artworks" ON public.artworks FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins update forum discussions" ON public.forum_discussions;
CREATE POLICY "Admins update forum discussions" ON public.forum_discussions FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins insert trend tags" ON public.trend_tags;
CREATE POLICY "Admins insert trend tags" ON public.trend_tags FOR INSERT TO authenticated WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins update trend tags" ON public.trend_tags;
CREATE POLICY "Admins update trend tags" ON public.trend_tags FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins insert community events" ON public.community_events;
CREATE POLICY "Admins insert community events" ON public.community_events FOR INSERT TO authenticated WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins update community events" ON public.community_events;
CREATE POLICY "Admins update community events" ON public.community_events FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins insert community stats" ON public.community_stats;
CREATE POLICY "Admins insert community stats" ON public.community_stats FOR INSERT TO authenticated WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins update community stats" ON public.community_stats;
CREATE POLICY "Admins update community stats" ON public.community_stats FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Chat RLS policies
DROP POLICY IF EXISTS "Public read public channels" ON public.chat_channels;
CREATE POLICY "Public read public channels" ON public.chat_channels FOR SELECT USING (type = 'public');

DROP POLICY IF EXISTS "Members read their channels" ON public.chat_channels;
CREATE POLICY "Members read their channels" ON public.chat_channels FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_channel_members WHERE channel_id = id AND user_id = auth.uid())
);

DROP POLICY IF EXISTS "Authenticated users create channels" ON public.chat_channels;
CREATE POLICY "Authenticated users create channels" ON public.chat_channels FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Owners and admins update channels" ON public.chat_channels;
CREATE POLICY "Owners and admins update channels" ON public.chat_channels FOR UPDATE TO authenticated USING (
  EXISTS (SELECT 1 FROM public.chat_channel_members WHERE channel_id = id AND user_id = auth.uid() AND role IN ('owner', 'admin'))
) WITH CHECK (
  EXISTS (SELECT 1 FROM public.chat_channel_members WHERE channel_id = id AND user_id = auth.uid() AND role IN ('owner', 'admin'))
);

DROP POLICY IF EXISTS "Members read channel members" ON public.chat_channel_members;
CREATE POLICY "Members read channel members" ON public.chat_channel_members FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_channel_members cm WHERE cm.channel_id = channel_id AND cm.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Members read messages" ON public.chat_messages;
CREATE POLICY "Members read messages" ON public.chat_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_channel_members WHERE channel_id = chat_messages.channel_id AND user_id = auth.uid())
);

DROP POLICY IF EXISTS "Members insert messages" ON public.chat_messages;
CREATE POLICY "Members insert messages" ON public.chat_messages FOR INSERT TO authenticated WITH CHECK (
  auth.uid() = author_id AND EXISTS (SELECT 1 FROM public.chat_channel_members WHERE channel_id = chat_messages.channel_id AND user_id = auth.uid())
);

DROP POLICY IF EXISTS "Authors update own messages" ON public.chat_messages;
CREATE POLICY "Authors update own messages" ON public.chat_messages FOR UPDATE TO authenticated USING (auth.uid() = author_id) WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Users read their groups" ON public.chat_groups;
CREATE POLICY "Users read their groups" ON public.chat_groups FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_group_members WHERE group_id = id AND user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users create groups" ON public.chat_groups;
CREATE POLICY "Users create groups" ON public.chat_groups FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Group members read members" ON public.chat_group_members;
CREATE POLICY "Group members read members" ON public.chat_group_members FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_group_members gm WHERE gm.group_id = chat_group_members.group_id AND gm.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users read their relationships" ON public.user_relationships;
CREATE POLICY "Users read their relationships" ON public.user_relationships FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = target_id);

DROP POLICY IF EXISTS "Users create relationships" ON public.user_relationships;
CREATE POLICY "Users create relationships" ON public.user_relationships FOR INSERT TO authenticated WITH CHECK (auth.uid() = requester_id);

DROP POLICY IF EXISTS "Users read presence" ON public.user_presence;
CREATE POLICY "Users read presence" ON public.user_presence FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users update own presence" ON public.user_presence;
CREATE POLICY "Users update own presence" ON public.user_presence FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users upsert own presence" ON public.user_presence;
CREATE POLICY "Users upsert own presence" ON public.user_presence FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);