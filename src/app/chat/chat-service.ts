import type { Session } from "@supabase/supabase-js";
import { hasSupabaseEnv, supabase } from "../lib/supabase";
import type {
  ChatChannel,
  ChatChannelMember,
  ChatGroup,
  ChatGroupMember,
  ChatMessage,
  MemberRole,
  MessageReaction,
  UserPresence,
  UserRelationship,
} from "./chat-types";

/* ───── Authenticated helpers ───── */

function mustHaveSupabase() {
  if (!hasSupabaseEnv || !supabase)
    throw new Error("Supabase n'est pas configuré.");
  return supabase;
}

function mustHaveSession(session: Session | null): string {
  if (!session?.user?.id) throw new Error("Session requise.");
  return session.user.id;
}

/* ───── Channels ───── */

export async function fetchChannels() {
  const sb = mustHaveSupabase();
  const { data, error } = await sb
    .from("chat_channels")
    .select("*")
    .order("sort_order", { ascending: true });
  if (error) throw error;
  return data as ChatChannel[];
}

export async function fetchChannelById(id: string) {
  const sb = mustHaveSupabase();
  const { data, error } = await sb
    .from("chat_channels")
    .select("*")
    .eq("id", id)
    .single();
  if (error) throw error;
  return data as ChatChannel;
}

export async function createChannel(
  name: string,
  description: string,
  type: "public" | "private",
  categorySlug: string | null,
) {
  const sb = mustHaveSupabase();

  // First get the current user's profile
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { data: channel, error } = await sb
    .from("chat_channels")
    .insert({
      name,
      description,
      type,
      category_slug: categorySlug,
      created_by: user.id,
    })
    .select()
    .single();
  if (error) throw error;

  // Auto-join the creator as owner
  const { error: memberError } = await sb
    .from("chat_channel_members")
    .insert({
      channel_id: channel.id,
      user_id: user.id,
      role: "owner",
    });
  if (memberError) throw memberError;

  return channel as ChatChannel;
}

export async function joinChannel(channelId: string) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { error } = await sb
    .from("chat_channel_members")
    .insert({ channel_id: channelId, user_id: user.id, role: "member" });
  if (error) throw error;
}

export async function leaveChannel(channelId: string) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { error } = await sb
    .from("chat_channel_members")
    .delete()
    .eq("channel_id", channelId)
    .eq("user_id", user.id);
  if (error) throw error;
}

export async function updateChannelMemberRole(
  channelId: string,
  userId: string,
  role: MemberRole,
) {
  const sb = mustHaveSupabase();
  const { error } = await sb
    .from("chat_channel_members")
    .update({ role })
    .eq("channel_id", channelId)
    .eq("user_id", userId);
  if (error) throw error;
}

export async function deleteChannel(channelId: string) {
  const sb = mustHaveSupabase();
  const { error } = await sb
    .from("chat_channels")
    .delete()
    .eq("id", channelId);
  if (error) throw error;
}

/* ───── Messages ───── */

export async function fetchMessages(
  channelId: string,
  limit = 50,
  beforeId?: string,
) {
  const sb = mustHaveSupabase();
  let query = sb
    .from("chat_messages")
    .select("*, author:author_id(email)")
    .eq("channel_id", channelId)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (beforeId) {
    query = query.lt("id", beforeId);
  }

  const { data, error } = await query;
  if (error) throw error;

  return (data || []).reverse().map((msg) => ({
    ...msg,
    author_email: msg.author?.email ?? "Inconnu",
  })) as ChatMessage[];
}

export async function sendMessage(
  channelId: string,
  content: string,
  replyTo?: string,
  attachmentUrl?: string,
) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");
  if (!content.trim()) throw new Error("Message vide.");

  const { data, error } = await sb
    .from("chat_messages")
    .insert({
      channel_id: channelId,
      author_id: user.id,
      content: content.trim(),
      reply_to: replyTo ?? null,
      attachment_url: attachmentUrl ?? null,
    })
    .select("*, author:author_id(email)")
    .single();
  if (error) throw error;

  return {
    ...data,
    author_email: data.author?.email ?? "Inconnu",
  } as ChatMessage;
}

export async function editMessage(messageId: string, content: string) {
  const sb = mustHaveSupabase();
  const { error } = await sb
    .from("chat_messages")
    .update({ content, edited_at: new Date().toISOString() })
    .eq("id", messageId);
  if (error) throw error;
}

export async function deleteMessage(messageId: string) {
  const sb = mustHaveSupabase();
  const { error } = await sb
    .from("chat_messages")
    .delete()
    .eq("id", messageId);
  if (error) throw error;
}

/* ───── Channel Members ───── */

export async function fetchChannelMembers(channelId: string) {
  const sb = mustHaveSupabase();
  const { data, error } = await sb
    .from("chat_channel_members")
    .select("*, profile:user_id(email)")
    .eq("channel_id", channelId);
  if (error) throw error;
  return (data || []).map((m) => ({
    ...m,
    email: m.profile?.email ?? "Inconnu",
  })) as ChatChannelMember[];
}

/* ───── Groups ───── */

export async function fetchGroups() {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return [];

  const { data, error } = await sb
    .from("chat_group_members")
    .select("group:group_id(*)")
    .eq("user_id", user.id);
  if (error) throw error;
  return ((data || []).map((item: Record<string, unknown>) => item.group) as unknown) as ChatGroup[];
}

export async function createGroup(
  name: string,
  description: string,
  maxMembers = 10000,
) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { data: group, error } = await sb
    .from("chat_groups")
    .insert({ name, description, max_members: maxMembers, created_by: user.id })
    .select()
    .single();
  if (error) throw error;

  // Auto-join creator as owner
  await sb.from("chat_group_members").insert({
    group_id: group.id,
    user_id: user.id,
    role: "owner",
  });

  return group as ChatGroup;
}

export async function joinGroup(groupId: string) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { error } = await sb
    .from("chat_group_members")
    .insert({ group_id: groupId, user_id: user.id, role: "member" });
  if (error) throw error;
}

export async function leaveGroup(groupId: string) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { error } = await sb
    .from("chat_group_members")
    .delete()
    .eq("group_id", groupId)
    .eq("user_id", user.id);
  if (error) throw error;
}

/* ───── Friends / Relationships ───── */

export async function fetchFriends() {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return { friends: [], pending: [] };

  const { data, error } = await sb
    .from("user_relationships")
    .select("*, requester:requester_id(email), target:target_id(email)")
    .or(`requester_id.eq.${user.id},target_id.eq.${user.id}`);
  if (error) throw error;

  const rels = (data || []).map((r) => ({
    ...r,
    requester_email: r.requester?.email,
    target_email: r.target?.email,
  }));

  const friends = rels.filter((r) => r.status === "accepted");
  const pending = rels.filter(
    (r) => r.status === "pending" && r.target_id === user.id,
  );

  return { friends, pending } as {
    friends: UserRelationship[];
    pending: UserRelationship[];
  };
}

export async function sendFriendRequest(targetEmail: string) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  // Find target user by email
  const { data: profiles, error: profileError } = await sb
    .from("profiles")
    .select("id, email")
    .eq("email", targetEmail)
    .limit(1);
  if (profileError) throw profileError;
  if (!profiles || profiles.length === 0)
    throw new Error("Utilisateur introuvable.");

  const target = profiles[0];
  if (target.id === user.id) throw new Error("Tu ne peux pas t'ajouter toi-même.");

  const { error } = await sb.from("user_relationships").insert({
    requester_id: user.id,
    target_id: target.id,
    status: "pending",
  });
  if (error) throw error;
}

export async function acceptFriendRequest(requesterId: string) {
  const sb = mustHaveSupabase();
  const { error } = await sb
    .from("user_relationships")
    .update({ status: "accepted" })
    .eq("requester_id", requesterId)
    .eq("target_id", (await sb.auth.getUser()).data.user?.id ?? "");
  if (error) throw error;
}

export async function declineFriendRequest(requesterId: string) {
  const sb = mustHaveSupabase();
  const { error } = await sb
    .from("user_relationships")
    .delete()
    .eq("requester_id", requesterId)
    .eq("status", "pending");
  if (error) throw error;
}

/* ───── Presence ───── */

export async function updatePresence(status: "online" | "idle" | "offline") {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return;

  await sb.from("user_presence").upsert(
    {
      user_id: user.id,
      status,
      last_seen_at: new Date().toISOString(),
    },
    { onConflict: "user_id" },
  );
}

export async function fetchPresence() {
  const sb = mustHaveSupabase();
  const { data, error } = await sb
    .from("user_presence")
    .select("*, profile:user_id(email)")
    .order("last_seen_at", { ascending: false });
  if (error) throw error;
  return (data || []).map((p) => ({
    ...p,
    email: p.profile?.email ?? "Inconnu",
  })) as (UserPresence & { email: string })[];
}

/* ───── Realtime Subscriptions ───── */

export function subscribeToMessages(
  channelId: string,
  onMessage: (message: ChatMessage) => void,
) {
  const sb = mustHaveSupabase();
  const subscription = sb
    .channel(`messages:${channelId}`)
    .on(
      "postgres_changes",
      {
        event: "INSERT",
        schema: "public",
        table: "chat_messages",
        filter: `channel_id=eq.${channelId}`,
      },
      async (payload) => {
        // Fetch the full message with author info
        const { data } = await sb
          .from("chat_messages")
          .select("*, author:author_id(email)")
          .eq("id", payload.new.id)
          .single();
        if (data) {
          onMessage({
            ...data,
            author_email: data.author?.email ?? "Inconnu",
          } as ChatMessage);
        }
      },
    )
    .subscribe();

  return () => {
    sb.removeChannel(subscription);
  };
}

export function subscribeToPresence(
  onPresence: (presence: UserPresence & { email: string }) => void,
) {
  const sb = mustHaveSupabase();
  const subscription = sb
    .channel("presence-changes")
    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "user_presence",
      },
      async (payload) => {
        const newRow = payload.new as UserPresence;
        const { data: profile } = await sb
          .from("profiles")
          .select("email")
          .eq("id", newRow.user_id)
          .single();
        onPresence({
          ...newRow,
          email: profile?.email ?? "Inconnu",
        });
      },
    )
    .subscribe();

  return () => {
    sb.removeChannel(subscription);
  };
}

export function subscribeToFriendRequests(
  userId: string,
  onRequest: (rel: UserRelationship) => void,
) {
  const sb = mustHaveSupabase();
  const subscription = sb
    .channel("friend-requests")
    .on(
      "postgres_changes",
      {
        event: "INSERT",
        schema: "public",
        table: "user_relationships",
        filter: `target_id=eq.${userId}`,
      },
      (payload) => {
        onRequest(payload.new as UserRelationship);
      },
    )
    .subscribe();

  return () => {
    sb.removeChannel(subscription);
  };
}

/* ───── Voice Messages ───── */

export async function uploadVoiceMessage(
  audioBlob: Blob,
  channelId: string,
): Promise<string> {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const fileName = `${channelId}/${user.id}/${Date.now()}-voice.webm`;

  const { error } = await sb.storage
    .from("chat-attachments")
    .upload(fileName, audioBlob, {
      contentType: "audio/webm",
    });
  if (error) throw error;

  const { data: urlData } = sb.storage
    .from("chat-attachments")
    .getPublicUrl(fileName);

  return urlData.publicUrl;
}

export async function sendVoiceMessage(
  channelId: string,
  voiceUrl: string,
  duration: number,
) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { data, error } = await sb
    .from("chat_messages")
    .insert({
      channel_id: channelId,
      author_id: user.id,
      content: "🎤 Message vocal",
      message_type: "voice",
      voice_url: voiceUrl,
      voice_duration: duration,
    })
    .select("*, author:author_id(email)")
    .single();
  if (error) throw error;

  return {
    ...data,
    author_email: data.author?.email ?? "Inconnu",
  } as ChatMessage;
}

/* ───── Sticker Messages ───── */

export async function sendStickerMessage(
  channelId: string,
  stickerId: string,
  stickerUrl: string,
) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { data, error } = await sb
    .from("chat_messages")
    .insert({
      channel_id: channelId,
      author_id: user.id,
      content: stickerUrl,
      message_type: "sticker",
      sticker_id: stickerId,
    })
    .select("*, author:author_id(email)")
    .single();
  if (error) throw error;

  return {
    ...data,
    author_email: data.author?.email ?? "Inconnu",
  } as ChatMessage;
}

/* ───── GIF Messages ───── */

export async function sendGifMessage(
  channelId: string,
  gifUrl: string,
) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const { data, error } = await sb
    .from("chat_messages")
    .insert({
      channel_id: channelId,
      author_id: user.id,
      content: gifUrl,
      message_type: "gif",
    })
    .select("*, author:author_id(email)")
    .single();
  if (error) throw error;

  return {
    ...data,
    author_email: data.author?.email ?? "Inconnu",
  } as ChatMessage;
}

/* ───── File Upload ───── */

export async function uploadChatFile(
  file: File,
  channelId: string,
): Promise<string> {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const ext = file.name.split(".").pop() || "bin";
  const fileName = `${channelId}/${user.id}/${Date.now()}-${file.name.replace(/[^a-zA-Z0-9.-]/g, "_")}`;

  const { error } = await sb.storage
    .from("chat-attachments")
    .upload(fileName, file, {
      contentType: file.type || `application/${ext}`,
    });
  if (error) throw error;

  const { data: urlData } = sb.storage
    .from("chat-attachments")
    .getPublicUrl(fileName);

  return urlData.publicUrl;
}

export async function sendFileMessage(
  channelId: string,
  fileUrl: string,
  fileName: string,
) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  const isImage = /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(fileName);
  const { data, error } = await sb
    .from("chat_messages")
    .insert({
      channel_id: channelId,
      author_id: user.id,
      content: isImage ? "" : `📎 ${fileName}`,
      message_type: isImage ? "image" : "file",
      attachment_url: fileUrl,
    })
    .select("*, author:author_id(email)")
    .single();
  if (error) throw error;

  return {
    ...data,
    author_email: data.author?.email ?? "Inconnu",
  } as ChatMessage;
}

/* ───── Reactions ───── */

export async function addReaction(
  messageId: string,
  emoji: string,
) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) throw new Error("Session requise.");

  // Check if reaction already exists
  const { data: existing } = await sb
    .from("chat_message_reactions")
    .select("id")
    .eq("message_id", messageId)
    .eq("user_id", user.id)
    .eq("emoji", emoji)
    .single();

  if (existing) {
    // Remove existing reaction (toggle)
    await sb
      .from("chat_message_reactions")
      .delete()
      .eq("id", existing.id);
    return false; // removed
  }

  const { error } = await sb
    .from("chat_message_reactions")
    .insert({
      message_id: messageId,
      user_id: user.id,
      emoji,
    });
  if (error) throw error;
  return true; // added
}

export async function fetchReactions(
  messageIds: string[],
): Promise<Map<string, MessageReaction[]>> {
  const sb = mustHaveSupabase();
  if (messageIds.length === 0) return new Map();

  const { data, error } = await sb
    .from("chat_message_reactions")
    .select("*")
    .in("message_id", messageIds);
  if (error) throw error;

  const map = new Map<string, MessageReaction[]>();
  for (const r of data || []) {
    const existing = map.get(r.message_id) || [];
    existing.push(r as MessageReaction);
    map.set(r.message_id, existing);
  }
  return map;
}

/* ───── Pin Messages ───── */

export async function togglePinMessage(messageId: string) {
  const sb = mustHaveSupabase();
  const { data: msg } = await sb
    .from("chat_messages")
    .select("is_pinned")
    .eq("id", messageId)
    .single();

  const { error } = await sb
    .from("chat_messages")
    .update({ is_pinned: !(msg?.is_pinned ?? false) })
    .eq("id", messageId);
  if (error) throw error;
}

export async function fetchPinnedMessages(channelId: string) {
  const sb = mustHaveSupabase();
  const { data, error } = await sb
    .from("chat_messages")
    .select("*, author:author_id(email)")
    .eq("channel_id", channelId)
    .eq("is_pinned", true)
    .order("created_at", { ascending: false });
  if (error) throw error;

  return (data || []).map((msg) => ({
    ...msg,
    author_email: msg.author?.email ?? "Inconnu",
  })) as ChatMessage[];
}

/* ───── Typing Indicators ───── */

export async function setTyping(channelId: string, isTyping: boolean) {
  const sb = mustHaveSupabase();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return;

  if (isTyping) {
    await sb.from("typing_indicators").upsert(
      {
        user_id: user.id,
        channel_id: channelId,
        started_at: new Date().toISOString(),
      },
      { onConflict: "user_id,channel_id" },
    );
  } else {
    await sb
      .from("typing_indicators")
      .delete()
      .eq("user_id", user.id)
      .eq("channel_id", channelId);
  }
}

export function subscribeToTyping(
  channelId: string,
  onTypingChange: (typing: { user_id: string; email: string }[]) => void,
) {
  const sb = mustHaveSupabase();
  const subscription = sb
    .channel(`typing:${channelId}`)
    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "typing_indicators",
        filter: `channel_id=eq.${channelId}`,
      },
      async () => {
        // Fetch current typing users for this channel
        const { data } = await sb
          .from("typing_indicators")
          .select("user_id, started_at, profile:user_id(email)")
          .eq("channel_id", channelId);

        // Filter out users typing for more than 10 seconds
        const now = Date.now();
        const active = (data || []).filter((t) => {
          const elapsed = now - new Date(t.started_at).getTime();
          return elapsed < 10000;
        });

        onTypingChange(
          active.map((t) => ({
            user_id: t.user_id,
            email: (t.profile as unknown as { email?: string })?.email ?? "Inconnu",
          })),
        );
      },
    )
    .subscribe();

  return () => {
    sb.removeChannel(subscription);
  };
}

/* ───── Search Messages ───── */

export async function searchMessages(channelId: string, query: string) {
  const sb = mustHaveSupabase();
  const { data, error } = await sb
    .from("chat_messages")
    .select("*, author:author_id(email)")
    .eq("channel_id", channelId)
    .ilike("content", `%${query}%`)
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) throw error;

  return (data || []).map((msg) => ({
    ...msg,
    author_email: msg.author?.email ?? "Inconnu",
  })) as ChatMessage[];
}
