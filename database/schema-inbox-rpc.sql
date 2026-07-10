-- ============================================================
-- Artéïa - RPC pour charger l'inbox en une seule requête
-- ============================================================

create or replace function public.get_inbox_conversations(current_user_id uuid)
returns table (
  channel_id uuid,
  other_user_id uuid,
  username text,
  avatar_url text,
  last_message text,
  last_message_at timestamptz,
  is_online boolean,
  presence_status text
) language sql security definer as $$
  with my_direct_channels as (
    select cm.channel_id
    from public.channel_members cm
    join public.channels c on c.id = cm.channel_id
    where cm.user_id = current_user_id
      and c.type = 'direct'
  ),
  other_members as (
    select cm.channel_id, cm.user_id as other_user_id
    from public.channel_members cm
    where cm.channel_id in (select channel_id from my_direct_channels)
      and cm.user_id <> current_user_id
  ),
  last_messages as (
    select distinct on (m.channel_id) m.channel_id, m.content, m.created_at
    from public.messages m
    where m.channel_id in (select channel_id from my_direct_channels)
    order by m.channel_id, m.created_at desc
  )
  select
    om.channel_id,
    om.other_user_id,
    p.username,
    p.avatar_url,
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
