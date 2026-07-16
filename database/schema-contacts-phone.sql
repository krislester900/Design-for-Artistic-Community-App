-- ============================================================
-- Artéïa - Contacts & Phone Number Support
-- Migration pour la détection des contacts par numéro de téléphone
-- ============================================================

-- 1. Ajouter phone_number et username aux profils
alter table if exists public.profiles 
  add column if not exists phone_number text,
  add column if not exists username text unique,
  add column if not exists updated_at timestamptz not null default now();

-- 2. Index pour la recherche par téléphone
create index if not exists idx_profiles_phone_number on public.profiles(phone_number);
create index if not exists idx_profiles_username on public.profiles(username);
create index if not exists idx_profiles_email_lower on public.profiles(lower(email));

-- 3. Table des connexions utilisateur (contacts de l'app)
create table if not exists public.user_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  contact_id uuid not null references public.profiles(id) on delete cascade,
  contact_name text not null,
  contact_email text,
  contact_avatar text,
  contact_bio text,
  contact_phone text,
  contact_country_code text,
  status text not null check (status in ('pending', 'accepted', 'blocked')) default 'pending',
  connection_type text not null check (connection_type in ('friend', 'colleague', 'family', 'other')) default 'friend',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, contact_id)
);

create index if not exists idx_user_connections_user on public.user_connections(user_id);
create index if not exists idx_user_connections_contact on public.user_connections(contact_id);
create index if not exists idx_user_connections_status on public.user_connections(status);

-- 4. Table des canaux de discussion privés (DM)
create table if not exists public.chat_channels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  user1_id uuid not null references public.profiles(id) on delete cascade,
  user2_id uuid not null references public.profiles(id) on delete cascade,
  last_message_at timestamptz,
  is_group boolean not null default false,
  created_at timestamptz not null default now(),
  check (user1_id != user2_id)
);

create index if not exists idx_chat_channels_user1 on public.chat_channels(user1_id);
create index if not exists idx_chat_channels_user2 on public.chat_channels(user2_id);
create index if not exists idx_chat_channels_last_message on public.chat_channels(last_message_at desc);

-- 5. Table des messages privés
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.chat_channels(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  message_type text not null check (message_type in ('text', 'image', 'voice', 'file', 'system')) default 'text',
  sender_name text,
  sender_avatar text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_messages_channel on public.chat_messages(channel_id, created_at);
create index if not exists idx_chat_messages_sender on public.chat_messages(sender_id);
create index if not exists idx_chat_messages_receiver_read on public.chat_messages(receiver_id, is_read);

-- 6. Table des préférences d'interaction utilisateur
create table if not exists public.user_interaction_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  response_style text check (response_style in ('concise', 'detailed', 'balanced')) default 'balanced',
  metaphor_usage text check (metaphor_usage in ('high', 'medium', 'low')) default 'medium',
  updated_at timestamptz not null default now()
);

-- ============================================================
-- RLS POLICIES
-- ============================================================

alter table public.profiles enable row level security;
alter table public.user_connections enable row level security;
alter table public.chat_channels enable row level security;
alter table public.chat_messages enable row level security;
alter table public.user_interaction_preferences enable row level security;

-- Profiles: public read, users update their own
drop policy if exists "Public read profiles" on public.profiles;
create policy "Public read profiles" on public.profiles for select using (true);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update using (auth.uid() = id);

-- User connections: owner can manage
drop policy if exists "Users manage own connections" on public.user_connections;
create policy "Users manage own connections" on public.user_connections
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Chat channels: participants can read/write
drop policy if exists "Channel participants read" on public.chat_channels;
create policy "Channel participants read" on public.chat_channels
  for select using (auth.uid() = user1_id or auth.uid() = user2_id);

drop policy if exists "Users create channels" on public.chat_channels;
create policy "Users create channels" on public.chat_channels
  for insert to authenticated with check (auth.uid() = user1_id);

-- Chat messages: participants can read/write
drop policy if exists "Channel participants read messages" on public.chat_messages;
create policy "Channel participants read messages" on public.chat_messages
  for select using (
    auth.uid() = (
      select user1_id from public.chat_channels where id = channel_id
    ) or 
    auth.uid() = (
      select user2_id from public.chat_channels where id = channel_id
    )
  );

drop policy if exists "Users send messages" on public.chat_messages;
create policy "Users send messages" on public.chat_messages
  for insert to authenticated with check (auth.uid() = sender_id);

-- User interaction preferences: owner only
drop policy if exists "Users manage own preferences" on public.user_interaction_preferences;
create policy "Users manage own preferences" on public.user_interaction_preferences
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Fonction pour créer un canal DM entre deux utilisateurs
create or replace function public.create_dm_channel(user1 uuid, user2 uuid)
returns uuid as $$
declare
  channel_id uuid;
  sorted_ids uuid[];
begin
  sorted_ids := array[user1, user2];
  sorted_ids := (select array_agg(x order by x) from unnest(sorted_ids) as t(x));
  
  select id into channel_id from public.chat_channels 
  where user1_id = sorted_ids[1] and user2_id = sorted_ids[2];
  
  if channel_id is null then
    insert into public.chat_channels (user1_id, user2_id, created_at)
    values (sorted_ids[1], sorted_ids[2], now())
    returning id into channel_id;
  end if;
  
  return channel_id;
end;
$$ language plpgsql security definer;

-- Fonction pour obtenir les conversations de l'utilisateur (inbox)
create or replace function public.get_user_inbox(current_user uuid)
returns table (
  channel_id uuid,
  other_user_id uuid,
  other_user_name text,
  other_user_avatar text,
  last_message text,
  last_message_at timestamptz,
  is_online boolean
) as $$
begin
  return query
  select 
    c.id as channel_id,
    (case when c.user1_id = current_user then c.user2_id else c.user1_id end) as other_user_id,
    p.display_name as other_user_name,
    p.avatar_url as other_user_avatar,
    m.content as last_message,
    c.last_message_at,
    false as is_online
  from public.chat_channels c
  left join public.chat_messages m on m.channel_id = c.id
  left join public.profiles p on p.id = (case when c.user1_id = current_user then c.user2_id else c.user1_id end)
  where c.user1_id = current_user or c.user2_id = current_user
  order by c.last_message_at desc nulls last;
end;
$$ language plpgsql security definer;