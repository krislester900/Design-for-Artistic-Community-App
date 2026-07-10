import { supabase, hasSupabaseEnv } from "../lib/supabase";
import type { Notification } from "./notifications";
import type { ChatChannel, ChatMessage } from "../chat/chat-types";

export interface DMConversation {
  channel_id: string;
  other_user_id: string;
  other_email: string;
  last_message: string | null;
  last_message_at: string | null;
  is_online: boolean;
  presence_status: string;
}

export interface ChannelWithUnread {
  channel: ChatChannel;
  last_message?: string;
  last_message_at?: string;
  last_author?: string;
  unread_count: number;
}

export interface InboxNotificationsGroup {
  notifications: Notification[];
  unread_count: number;
}

export async function getCurrentUserId(): Promise<string | null> {
  if (!hasSupabaseEnv || !supabase) return null;
  const { data: { user } } = await supabase.auth.getUser();
  return user?.id ?? null;
}

export async function getDMConversations(): Promise<DMConversation[]> {
  if (!hasSupabaseEnv || !supabase) return [];
  const userId = await getCurrentUserId();
  if (!userId) return [];

  // Try RPC first
  const { data: rpcData, error: rpcError } = await supabase
    .rpc("get_dm_conversations", { current_user_id: userId });

  if (!rpcError && rpcData) return rpcData as DMConversation[];

  // Fallback: direct query
  const { data: myChannels } = await supabase
    .from("chat_channel_members")
    .select("channel_id")
    .eq("user_id", userId);

  if (!myChannels) return [];

  const channelIds = myChannels.map((m) => m.channel_id);
  if (channelIds.length === 0) return [];

  const { data: channels } = await supabase
    .from("chat_channels")
    .select("id")
    .in("id", channelIds)
    .eq("type", "dm");

  if (!channels) return [];

  const dmIds = channels.map((c) => c.id);
  if (dmIds.length === 0) return [];

  const { data: otherMembers } = await supabase
    .from("chat_channel_members")
    .select("channel_id, user_id")
    .in("channel_id", dmIds)
    .neq("user_id", userId);

  if (!otherMembers) return [];

  const conversations = await Promise.all(
    otherMembers.map(async (om) => {
      const { data: profile } = await supabase
        .from("profiles")
        .select("email")
        .eq("id", om.user_id)
        .single();

      const { data: lastMsg } = await supabase
        .from("chat_messages")
        .select("content, created_at")
        .eq("channel_id", om.channel_id)
        .order("created_at", { ascending: false })
        .limit(1);

      const { data: presence } = await supabase
        .from("user_presence")
        .select("status")
        .eq("user_id", om.user_id)
        .single();

      return {
        channel_id: om.channel_id,
        other_user_id: om.user_id,
        other_email: profile?.email ?? "Inconnu",
        last_message: lastMsg?.[0]?.content ?? null,
        last_message_at: lastMsg?.[0]?.created_at ?? null,
        is_online: presence?.status === "online",
        presence_status: presence?.status ?? "offline",
      };
    }),
  );

  return conversations.sort((a, b) => {
    if (!a.last_message_at) return 1;
    if (!b.last_message_at) return -1;
    return b.last_message_at.localeCompare(a.last_message_at);
  });
}

export async function getChannelsWithUnread(): Promise<ChannelWithUnread[]> {
  if (!hasSupabaseEnv || !supabase) return [];
  const userId = await getCurrentUserId();
  if (!userId) return [];

  const { data: channels } = await supabase
    .from("chat_channels")
    .select("*")
    .order("sort_order", { ascending: true });

  if (!channels) return [];

  const results = await Promise.all(
    channels.map(async (ch) => {
      const { count: msgCount } = await supabase
        .from("chat_messages")
        .select("*", { count: "exact", head: true })
        .eq("channel_id", ch.id);

      const { data: lastMsg } = await supabase
        .from("chat_messages")
        .select("content, created_at, author_id")
        .eq("channel_id", ch.id)
        .order("created_at", { ascending: false })
        .limit(1);

      return {
        channel: ch as ChatChannel,
        last_message: lastMsg?.[0]?.content,
        last_message_at: lastMsg?.[0]?.created_at,
        unread_count: msgCount ?? 0,
      } as ChannelWithUnread;
    }),
  );

  return results;
}

export async function getNotificationsWithCount(limit = 20): Promise<InboxNotificationsGroup> {
  if (!hasSupabaseEnv || !supabase) {
    return { notifications: [], unread_count: 0 };
  }
  const userId = await getCurrentUserId();
  if (!userId) return { notifications: [], unread_count: 0 };

  const { data: rpcData, error: rpcError } = await supabase
    .rpc("get_notifications_with_count", { current_user_id: userId })
    .limit(limit);

  if (!rpcError && rpcData) {
    const items = rpcData as Notification[] & { unread_count: number };
    const unread = rpcData.length > 0 ? (rpcData[0] as unknown as Record<string, unknown>).unread_count as number : 0;
    return {
      notifications: items as unknown as Notification[],
      unread_count: Number(unread) ?? 0,
    };
  }

  // Fallback
  const { data, count } = await supabase
    .from("notifications")
    .select("*", { count: "estimated" })
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(limit);

  const unreadArr = data?.filter((n) => !n.is_read) ?? [];

  return {
    notifications: (data as Notification[]) ?? [],
    unread_count: count ?? unreadArr.length,
  };
}

export async function markAllNotificationsRead(): Promise<void> {
  if (!hasSupabaseEnv || !supabase) return;
  const userId = await getCurrentUserId();
  if (!userId) return;
  await supabase
    .from("notifications")
    .update({ is_read: true })
    .eq("user_id", userId)
    .eq("is_read", false);
}

export async function markNotificationRead(id: string): Promise<void> {
  if (!hasSupabaseEnv || !supabase) return;
  await supabase
    .from("notifications")
    .update({ is_read: true })
    .eq("id", id);
}
