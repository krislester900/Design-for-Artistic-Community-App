import { supabase, hasSupabaseEnv } from "../lib/supabase";
import { getCurrentSession } from "./auth";
import { createNotification } from "./notifications";

export interface Favorite {
  id: string;
  user_id: string;
  target_type: "artist" | "artwork" | "discussion";
  target_id: string;
  created_at: string;
}

export async function toggleFavorite(
  targetType: Favorite["target_type"],
  targetId: string
): Promise<{ liked: boolean; error?: string }> {
  if (!hasSupabaseEnv) return { liked: false, error: "Supabase not configured" };
  const { user } = await getCurrentSession();
  if (!user) return { liked: false, error: "Not authenticated" };

  const { data: existing } = await supabase
    .from("user_favorites")
    .select("id")
    .eq("user_id", user.id)
    .eq("target_type", targetType)
    .eq("target_id", targetId)
    .single();

  if (existing) {
    await supabase.from("user_favorites").delete().eq("id", existing.id);
    return { liked: false };
  }

  const { error } = await supabase.from("user_favorites").insert({
    user_id: user.id,
    target_type: targetType,
    target_id: targetId,
  });

  if (error) return { liked: false, error: error.message };

  await createNotification(
    targetId,
    "favorite",
    "Nouveau favori",
    `${user.email} a ajouté un favori`,
    `/${targetType}/${targetId}`,
    user.id
  );

  return { liked: true };
}

export async function isFavorited(
  targetType: Favorite["target_type"],
  targetId: string
): Promise<boolean> {
  if (!hasSupabaseEnv) return false;
  const { user } = await getCurrentSession();
  if (!user) return false;

  const { count } = await supabase
    .from("user_favorites")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("target_type", targetType)
    .eq("target_id", targetId);

  return (count ?? 0) > 0;
}

export async function getFavorites(
  targetType?: Favorite["target_type"]
): Promise<Favorite[]> {
  if (!hasSupabaseEnv) return [];
  const { user } = await getCurrentSession();
  if (!user) return [];

  let query = supabase
    .from("user_favorites")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  if (targetType) {
    query = query.eq("target_type", targetType);
  }

  const { data } = await query;
  return (data as Favorite[]) ?? [];
}