export type ChannelType = "public" | "private" | "dm";

export type MemberRole = "owner" | "admin" | "member";

export type RelationshipStatus = "pending" | "accepted" | "blocked";

export type PresenceStatus = "online" | "idle" | "offline";

export type MessageType = "text" | "voice" | "sticker" | "gif" | "image" | "file";

export interface ChatChannel {
  id: string;
  name: string;
  type: ChannelType;
  category_slug: string | null;
  description: string;
  background_image: string | null;
  created_by: string;
  is_locked: boolean;
  sort_order: number;
  created_at: string;
}

export interface ChatChannelMember {
  channel_id: string;
  user_id: string;
  role: MemberRole;
  joined_at: string;
  // Joined profile data
  email?: string;
}

export interface ChatMessage {
  id: string;
  channel_id: string;
  author_id: string;
  content: string;
  reply_to: string | null;
  attachment_url: string | null;
  edited_at: string | null;
  created_at: string;
  // Joined profile data
  author_email?: string;
  // New fields
  message_type?: MessageType;
  voice_url?: string;
  voice_duration?: number;
  sticker_id?: string;
  reactions?: MessageReaction[];
  is_pinned?: boolean;
  is_read?: boolean;
}

export interface MessageReaction {
  id: string;
  message_id: string;
  user_id: string;
  emoji: string;
  created_at: string;
}

export interface ChatGroup {
  id: string;
  name: string;
  description: string;
  image: string | null;
  created_by: string;
  max_members: number;
  created_at: string;
}

export interface ChatGroupMember {
  group_id: string;
  user_id: string;
  role: MemberRole;
  joined_at: string;
  email?: string;
}

export interface UserRelationship {
  requester_id: string;
  target_id: string;
  status: RelationshipStatus;
  created_at: string;
  // Joined profile data
  target_email?: string;
  requester_email?: string;
}

export interface UserPresence {
  user_id: string;
  status: PresenceStatus;
  last_seen_at: string;
}

export interface Sticker {
  id: string;
  name: string;
  url: string;
  category: string;
  emoji?: string;
}

export interface StickerPack {
  id: string;
  name: string;
  stickers: Sticker[];
}

export interface TypingUser {
  user_id: string;
  email: string;
  channel_id: string;
  started_at: string;
}

export interface UnreadCount {
  channel_id: string;
  count: number;
  last_message_at: string;
}

export interface ChannelPreview {
  channel_id: string;
  last_message: string;
  last_message_at: string;
  last_author: string;
}