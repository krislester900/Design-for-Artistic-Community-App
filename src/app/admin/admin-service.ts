import type { Session } from "@supabase/supabase-js";
import { categories } from "../data/community";
import { hasSupabaseEnv, supabase } from "../lib/supabase";

export interface AdminProfile {
  id: string;
  email: string | null;
  role: "user" | "admin";
}

function ensureSupabase() {
  if (!hasSupabaseEnv || !supabase) {
    throw new Error("Supabase n’est pas configuré.");
  }

  return supabase;
}

export async function getAdminSession(): Promise<Session | null> {
  const client = ensureSupabase();
  const { data, error } = await client.auth.getSession();

  if (error) {
    throw error;
  }

  return data.session;
}

export async function getOwnAdminProfile(
  userId: string,
): Promise<AdminProfile | null> {
  const client = ensureSupabase();
  const { data, error } = await client
    .from("profiles")
    .select("id, email, role")
    .eq("id", userId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data;
}

export function subscribeToAdminAuth(
  callback: (session: Session | null) => void,
) {
  const client = ensureSupabase();
  return client.auth.onAuthStateChange((_event, session) => {
    callback(session);
  });
}

export async function signInAdmin(email: string, password: string) {
  const client = ensureSupabase();
  const { error } = await client.auth.signInWithPassword({ email, password });

  if (error) {
    throw error;
  }
}

export async function signUpAdmin(email: string, password: string) {
  const client = ensureSupabase();
  const { error } = await client.auth.signUp({ email, password });

  if (error) {
    throw error;
  }
}

export async function signOutAdmin() {
  const client = ensureSupabase();
  const { error } = await client.auth.signOut();

  if (error) {
    throw error;
  }
}

export async function syncDefaultCategories() {
  const client = ensureSupabase();
  const payload = categories.map((category, index) => ({
    slug: category.slug,
    name: category.name,
    short_label: category.shortLabel,
    description: category.description,
    icon: category.icon,
    color: category.color,
    target_section_id: category.targetSectionId,
    sort_order: index + 1,
  }));

  const { error } = await client.from("categories").upsert(payload, {
    onConflict: "slug",
  });

  if (error) {
    throw error;
  }
}

export async function createArtist(input: {
  name: string;
  category_slug: string;
  role: string;
  image: string;
  featured_work: string;
}) {
  const client = ensureSupabase();
  const { error } = await client.from("artists").insert({
    ...input,
    likes: 0,
  });

  if (error) {
    throw error;
  }
}

export async function createArtwork(input: {
  title: string;
  artist_name: string;
  category_slug: string;
  medium: string;
  image: string;
  height: string;
}) {
  const client = ensureSupabase();
  const { error } = await client.from("artworks").insert({
    ...input,
    likes: 0,
    views: 0,
  });

  if (error) {
    throw error;
  }
}

export async function createDiscussion(input: {
  title: string;
  author_name: string;
  category_slug: string;
  time_label: string;
  trending: boolean;
}) {
  const client = ensureSupabase();
  const { error } = await client.from("forum_discussions").insert({
    ...input,
    replies: 0,
  });

  if (error) {
    throw error;
  }
}

export async function createTrend(input: {
  tag: string;
  category_slug: string;
  sort_order: number;
}) {
  const client = ensureSupabase();
  const { error } = await client.from("trend_tags").insert({
    ...input,
    count_label: "0",
  });

  if (error) {
    throw error;
  }
}

export async function createEvent(input: {
  title: string;
  date_label: string;
  category_slug: string;
  sort_order: number;
}) {
  const client = ensureSupabase();
  const { error } = await client.from("community_events").insert(input);

  if (error) {
    throw error;
  }
}

export async function upsertStat(input: {
  label: string;
  number_label: string;
  sort_order: number;
}) {
  const client = ensureSupabase();
  const { error } = await client.from("community_stats").upsert(input, {
    onConflict: "label",
  });

  if (error) {
    throw error;
  }
}
