-- ============================================================
-- Artéïa - Script final pour Supabase
-- A copier-coller directement dans Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. PROFILS
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  avatar_url text,
  bio text default '',
  website text,
  role text default 'user',
  followers_count int default 0,
  following_count int default 0,
  artworks_count int default 0,
  is_verified boolean default false,
  phone_number text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Profil visible par tous" on public.profiles;
create policy "Profil visible par tous" on public.profiles for select using (true);

drop policy if exists "Modifier son propre profil" on public.profiles;
create policy "Modifier son propre profil" on public.profiles
  for update to authenticated using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Insérer son propre profil" on public.profiles;
create policy "Insérer son propre profil" on public.profiles
  for insert to authenticated with check (auth.uid() = id);

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
-- 2. CATÉGORIES - MIGRATION SAFE
-- ============================================================
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null default '',
  description text default '',
  icon text default '📝',
  color text default '#7C5CFC',
  sort_order int default 0,
  created_at timestamptz default now()
);

alter table public.categories enable row level security;

drop policy if exists "Public read categories" on public.categories;
create policy "Public read categories" on public.categories for select using (true);

do $$
begin
  if exists (select 1 from information_schema.tables where table_name = 'categories') then
    if exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'title') then
      alter table public.categories rename column title to name;
    end if;
  end if;
end $$;

insert into public.categories (slug, name, description, icon, color, sort_order) values
  ('visual-art', 'Arts Visuels', 'Galerie et discussions artistiques', '🎨', '#00D4AA', 1),
  ('music', 'Musique', 'Partagez vos créations musicales', '🎵', '#7C5CFC', 2),
  ('literature', 'Littérature', 'Poèmes, histoires et écrits', '✍️', '#FF6B9D', 3),
  ('manga', 'Manga', 'Mangas et illustrations japonaises', '📚', '#FFA500', 4),
  ('film', 'Films', 'Cinéma et productions vidéo', '🎬', '#00BFFF', 5),
  ('animation', 'Animation', 'Animations et motion design', '🎞️', '#FF69B4', 6)
on conflict (slug) do nothing;

-- ============================================================
-- 3. POSTS / ŒUVRES
-- ============================================================
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
  tags text[],
  mood text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.posts enable row level security;

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

-- ============================================================
-- 3. LIKES
-- ============================================================
create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  unique(post_id, user_id)
);

alter table public.likes enable row level security;

drop policy if exists "Public read likes" on public.likes;
create policy "Public read likes" on public.likes for select using (true);

drop policy if exists "Auth insert likes" on public.likes;
create policy "Auth insert likes" on public.likes
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Auth delete likes" on public.likes;
create policy "Auth delete likes" on public.likes
  for delete to authenticated using (auth.uid() = user_id);

-- ============================================================
-- 4. COMMENTAIRES
-- ============================================================
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  likes_count int default 0,
  created_at timestamptz default now()
);

alter table public.comments enable row level security;

drop policy if exists "Commentaires visibles par tous" on public.comments;
create policy "Commentaires visibles par tous" on public.comments for select using (true);

drop policy if exists "Commenter si connecté" on public.comments;
create policy "Commenter si connecté" on public.comments
  for insert to authenticated with check (auth.uid() = author_id);

drop policy if exists "Supprimer son commentaire" on public.comments;
create policy "Supprimer son commentaire" on public.comments
  for delete to authenticated using (auth.uid() = author_id);

-- ============================================================
-- 5. NOTIFICATIONS
-- ============================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('like', 'comment', 'follow', 'mention', 'favorite')),
  from_user_id uuid references public.profiles(id) on delete set null,
  post_id uuid references public.posts(id) on delete cascade,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz default now()
);

alter table public.notifications enable row level security;

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

-- ============================================================
-- 6. FOLLOWS
-- ============================================================
create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (follower_id, following_id),
  constraint no_self_follow check (follower_id <> following_id)
);

alter table public.follows enable row level security;

drop policy if exists "Follows visibles par tous" on public.follows;
create policy "Follows visibles par tous" on public.follows for select using (true);

drop policy if exists "Follow si connecté" on public.follows;
create policy "Follow si connecté" on public.follows
  for insert to authenticated with check (auth.uid() = follower_id);

drop policy if exists "Unfollow le sien" on public.follows;
create policy "Unfollow le sien" on public.follows
  for delete to authenticated using (auth.uid() = follower_id);

-- ============================================================
-- 7. CHAT - CANAUX, MEMBRES, MESSAGES
-- ============================================================
create table if not exists public.chat_channels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null check (type in ('general', 'category', 'group', 'direct', 'self')) default 'general',
  category text,
  icon text default '💬',
  created_by uuid references public.profiles(id) on delete set null,
  is_private boolean not null default false,
  sort_order int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.chat_channel_members (
  channel_id uuid not null references public.chat_channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('member', 'moderator', 'admin')) default 'member',
  joined_at timestamptz default now(),
  primary key (channel_id, user_id)
);

-- Migration safe pour chat_messages si elle existe déjà avec un ancien schéma
do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'chat_messages'
  ) then
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'chat_messages'
        and column_name = 'author_id'
    ) then
      alter table public.chat_messages add column author_id uuid;
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'chat_messages'
        and column_name = 'message_type'
    ) then
      alter table public.chat_messages add column message_type text not null default 'text';
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'chat_messages'
        and column_name = 'voice_url'
    ) then
      alter table public.chat_messages add column voice_url text;
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'chat_messages'
        and column_name = 'voice_duration'
    ) then
      alter table public.chat_messages add column voice_duration int default 0;
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'chat_messages'
        and column_name = 'is_read'
    ) then
      alter table public.chat_messages add column is_read boolean not null default false;
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'chat_messages'
        and column_name = 'is_pinned'
    ) then
      alter table public.chat_messages add column is_pinned boolean not null default false;
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'chat_messages'
        and column_name = 'reply_to'
    ) then
      alter table public.chat_messages add column reply_to uuid references public.chat_messages(id) on delete set null;
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'chat_messages'
        and column_name = 'updated_at'
    ) then
      alter table public.chat_messages add column updated_at timestamptz default now();
    end if;
  end if;
end $$;

alter table public.chat_channels enable row level security;
alter table public.chat_channel_members enable row level security;
alter table public.chat_messages enable row level security;

-- Canaux : lecture publique, création/auth
drop policy if exists "Public read channels" on public.chat_channels;
create policy "Public read channels" on public.chat_channels for select using (true);

drop policy if exists "Auth create channels" on public.chat_channels;
create policy "Auth create channels" on public.chat_channels
  for insert to authenticated with check (auth.uid() = created_by);

-- Membres : lecture publique
drop policy if exists "Public read channel members" on public.chat_channel_members;
create policy "Public read channel members" on public.chat_channel_members for select using (true);

-- Messages : lecture publique, écriture/auth
drop policy if exists "Public read chat messages" on public.chat_messages;
create policy "Public read chat messages" on public.chat_messages for select using (true);

drop policy if exists "Auth insert chat messages" on public.chat_messages;
create policy "Auth insert chat messages" on public.chat_messages
  for insert to authenticated with check (auth.uid() = author_id);

drop policy if exists "Users update own chat messages" on public.chat_messages;
create policy "Users update own chat messages" on public.chat_messages
  for update to authenticated using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

-- Canaux par défaut
insert into public.chat_channels (name, description, type, icon) values
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
-- 8. PRÉSENCE UTILISATEUR
-- ============================================================
create table if not exists public.user_presence (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  status text not null default 'offline',
  last_seen_at timestamptz default now()
);

alter table public.user_presence enable row level security;

drop policy if exists "Public read presence" on public.user_presence;
create policy "Public read presence" on public.user_presence for select using (true);

drop policy if exists "Users update own presence" on public.user_presence;
create policy "Users update own presence" on public.user_presence
  for all to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================
-- 9. RELATIONS UTILISATEURS
-- ============================================================
create table if not exists public.user_relationships (
  requester_id uuid not null references public.profiles(id) on delete cascade,
  target_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz default now(),
  primary key (requester_id, target_id),
  constraint different_users check (requester_id <> target_id)
);

alter table public.user_relationships enable row level security;

drop policy if exists "Users read own relationships" on public.user_relationships;
create policy "Users read own relationships" on public.user_relationships
  for select using (auth.uid() = requester_id or auth.uid() = target_id);

drop policy if exists "Users insert own relationships" on public.user_relationships;
create policy "Users insert own relationships" on public.user_relationships
  for insert to authenticated with check (auth.uid() = requester_id);

drop policy if exists "Users update own relationships" on public.user_relationships;
create policy "Users update own relationships" on public.user_relationships
  for update to authenticated using (auth.uid() = requester_id or auth.uid() = target_id)
  with check (auth.uid() = requester_id or auth.uid() = target_id);

drop policy if exists "Users delete own relationships" on public.user_relationships;
create policy "Users delete own relationships" on public.user_relationships
  for delete to authenticated using (auth.uid() = requester_id or auth.uid() = target_id);

-- ============================================================
-- 10. RPC INBOX
-- ============================================================
create or replace function public.get_dm_conversations(current_user_id uuid)
returns table (
  channel_id uuid,
  other_user_id uuid,
  other_email text,
  last_message text,
  last_message_at timestamptz,
  is_online boolean,
  presence_status text
) language sql security definer as $$
  with my_dm_channels as (
    select cm.channel_id
    from public.chat_channel_members cm
    join public.chat_channels c on c.id = cm.channel_id
    where cm.user_id = current_user_id
      and c.type = 'direct'
  ),
  other_members as (
    select cm.channel_id, cm.user_id as other_user_id
    from public.chat_channel_members cm
    where cm.channel_id in (select channel_id from my_dm_channels)
      and cm.user_id <> current_user_id
  ),
  last_messages as (
    select distinct on (m.channel_id) m.channel_id, m.content, m.created_at
    from public.chat_messages m
    where m.channel_id in (select channel_id from my_dm_channels)
    order by m.channel_id, m.created_at desc
  )
  select
    om.channel_id,
    om.other_user_id,
    p.email::text as other_email,
    lm.content as last_message,
    lm.created_at as last_message_at,
    case when up.status = 'online' then true else false end as is_online,
    up.status::text as presence_status
  from other_members om
  left join public.profiles p on p.id = om.other_user_id
  left join last_messages lm on lm.channel_id = om.channel_id
  left join public.user_presence up on up.user_id = om.other_user_id
  order by lm.created_at desc nulls last;
$$;

-- ============================================================
-- 11. STORAGE BUCKETS
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('artworks', 'artworks', true, 52428800, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('voice-messages', 'voice-messages', true, 52428800, null)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-attachments', 'chat-attachments', true, 52428800, null)
on conflict (id) do nothing;

-- Storage policies
drop policy if exists "Public read artworks" on storage.objects;
create policy "Public read artworks" on storage.objects
  for select using (bucket_id = 'artworks');

drop policy if exists "Auth upload artworks" on storage.objects;
create policy "Auth upload artworks" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'artworks' and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Public read voice messages" on storage.objects;
create policy "Public read voice messages" on storage.objects
  for select using (bucket_id = 'voice-messages');

drop policy if exists "Auth upload voice messages" on storage.objects;
create policy "Auth upload voice messages" on storage.objects
  for insert to authenticated with check (bucket_id = 'voice-messages');

drop policy if exists "Public read chat attachments" on storage.objects;
create policy "Public read chat attachments" on storage.objects
  for select using (bucket_id = 'chat-attachments');

drop policy if exists "Auth upload chat attachments" on storage.objects;
create policy "Auth upload chat attachments" on storage.objects
  for insert to authenticated with check (bucket_id = 'chat-attachments');

-- ============================================================
-- 12. INDEXES
-- ============================================================
create index if not exists idx_posts_category on public.posts(category_slug);
create index if not exists idx_posts_user on public.posts(user_id);
create index if not exists idx_posts_created on public.posts(created_at desc);
create index if not exists idx_likes_post on public.likes(post_id);
create index if not exists idx_comments_post on public.comments(post_id);
create index if not exists idx_notifications_user on public.notifications(user_id, is_read, created_at desc);
create index if not exists idx_chat_messages_channel_time on public.chat_messages(channel_id, created_at desc);
create index if not exists idx_chat_messages_user on public.chat_messages(author_id, created_at desc);
create index if not exists idx_channel_members_user on public.chat_channel_members(user_id);

-- ============================================================
-- 13. REALTIME
-- ============================================================
alter publication supabase_realtime add table public.posts;
alter publication supabase_realtime add table public.comments;
alter publication supabase_realtime add table public.likes;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.follows;
alter publication supabase_realtime add table public.chat_messages;

-- ============================================================
-- 14. TRIGGERS
-- ============================================================
create or replace function public.update_likes_count()
returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    update public.posts set likes_count = likes_count + 1 where id = new.post_id;
  elsif (tg_op = 'DELETE') then
    update public.posts set greatest(0, likes_count - 1) where id = old.post_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_like_change on public.likes;
create trigger on_like_change
  after insert or delete on public.likes
  for each row execute procedure public.update_likes_count();

create or replace function public.update_comments_count()
returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    update public.posts set comments_count = coalesce(comments_count, 0) + 1 where id = new.post_id;
  elsif (tg_op = 'DELETE') then
    update public.posts set greatest(0, coalesce(comments_count, 0) - 1) where id = old.post_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_comment_change on public.comments;
create trigger on_comment_change
  after insert or delete on public.comments
  for each row execute procedure public.update_comments_count();

create or replace function public.update_follow_counts()
returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    update public.profiles set followers_count = coalesce(followers_count, 0) + 1 where id = new.following_id;
    update public.profiles set following_count = coalesce(following_count, 0) + 1 where id = new.follower_id;
  elsif (tg_op = 'DELETE') then
    update public.profiles set greatest(0, coalesce(followers_count, 0) - 1) where id = old.following_id;
    update public.profiles set greatest(0, coalesce(following_count, 0) - 1) where id = old.follower_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_follow_change on public.follows;
create trigger on_follow_change
  after insert or delete on public.follows
  for each row execute procedure public.update_follow_counts();

-- ============================================================
-- FIN
-- ============================================================
do $$
begin
  raise notice '✅ Schéma consolidé Artéïa exécuté avec succès';
  raise notice '✅ Tables: profiles, posts, likes, comments, notifications, follows';
  raise notice '✅ Chat: chat_channels, chat_channel_members, chat_messages';
  raise notice '✅ RPC: get_dm_conversations';
  raise notice '✅ Storage: artworks, voice-messages, chat-attachments';
  raise notice '✅ Realtime activé sur les tables principales';
end $$;
