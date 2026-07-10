-- ============================================================
-- Arteia - RPC unifié pour l'inbox (DM + canaux + notifications)
-- Utilise les tables chat_* (pas le schéma channels/messages parallèle)
-- ============================================================

-- Récupère toutes les conversations DM de l'utilisateur
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
      and c.type = 'dm'
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

-- Récupère les notifications avec le compteur non lues
create or replace function public.get_notifications_with_count(current_user_id uuid)
returns table (
  id uuid,
  actor_id uuid,
  type text,
  title text,
  body text,
  link text,
  is_read boolean,
  created_at timestamptz,
  unread_count bigint
) language sql security definer as $$
  select
    n.id, n.actor_id, n.type::text, n.title, n.body,
    n.link, n.is_read, n.created_at,
    (select count(*) from public.notifications n2
     where n2.user_id = current_user_id and not n2.is_read) as unread_count
  from public.notifications n
  where n.user_id = current_user_id
  order by n.created_at desc;
$$;
