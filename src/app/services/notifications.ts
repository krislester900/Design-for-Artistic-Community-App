import { supabase, hasSupabaseEnv } from "../lib/supabase";
import { getCurrentSession } from "./auth";

export interface Notification {
  id: string;
  user_id: string;
  actor_id: string | null;
  type: "like" | "comment" | "follow" | "favorite" | "mention" | "system";
  title: string;
  body: string;
  link: string | null;
  is_read: boolean;
  created_at: string;
}

export async function getNotifications(limit = 20): Promise<Notification[]> {
  if (!hasSupabaseEnv) return [];
  const { user } = await getCurrentSession();
  if (!user) return [];

  const { data } = await supabase
    .from("notifications")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(limit);

  return (data as Notification[]) ?? [];
}

export async function getUnreadCount(): Promise<number> {
  if (!hasSupabaseEnv) return 0;
  const { user } = await getCurrentSession();
  if (!user) return 0;

  const { count } = await supabase
    .from("notifications")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("is_read", false);

  return count ?? 0;
}

export async function markAsRead(notificationId: string): Promise<void> {
  if (!hasSupabaseEnv) return;
  await supabase
    .from("notifications")
    .update({ is_read: true })
    .eq("id", notificationId);
}

export async function markAllAsRead(): Promise<void> {
  if (!hasSupabaseEnv) return;
  const { user } = await getCurrentSession();
  if (!user) return;

  await supabase
    .from("notifications")
    .update({ is_read: true })
    .eq("user_id", user.id)
    .eq("is_read", false);
}

export async function createNotification(
  userId: string,
  type: Notification["type"],
  title: string,
  body: string,
  link?: string,
  actorId?: string
): Promise<void> {
  if (!hasSupabaseEnv) return;

  await supabase.from("notifications").insert({
    user_id: userId,
    actor_id: actorId ?? null,
    type,
    title,
    body,
    link: link ?? null,
  });
}