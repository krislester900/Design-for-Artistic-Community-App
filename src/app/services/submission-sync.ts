/**
 * SubmissionSyncService — Pont entre localStorage et Supabase.
 * 
 * Ce service permet de :
 * 1. Synchroniser les soumissions approuvées (localStorage) vers Supabase
 * 2. Insérer directement dans Supabase quand un utilisateur authentifié soumet
 * 3. Récupérer l'historique des soumissions depuis Supabase
 */

import { hasSupabaseEnv, supabase } from "../lib/supabase";
import type { Artist, Artwork, Discussion } from "../data/community";

export interface SupabaseInsertResult {
  success: boolean;
  error?: string;
}

/**
 * Insère un artiste directement dans Supabase
 */
export async function insertArtistToSupabase(
  data: { name: string; category_slug: string; role: string; image: string; featured_work: string },
): Promise<SupabaseInsertResult> {
  if (!hasSupabaseEnv || !supabase) {
    return { success: false, error: "Supabase non configuré" };
  }
  const { error } = await supabase.from("artists").insert({ ...data, likes: 0 });
  if (error) return { success: false, error: error.message };
  return { success: true };
}

/**
 * Insère une œuvre directement dans Supabase
 */
export async function insertArtworkToSupabase(
  data: { title: string; artist_name: string; category_slug: string; medium: string; image: string; height: string },
): Promise<SupabaseInsertResult> {
  if (!hasSupabaseEnv || !supabase) {
    return { success: false, error: "Supabase non configuré" };
  }
  const { error } = await supabase.from("artworks").insert({ ...data, likes: 0, views: 0 });
  if (error) return { success: false, error: error.message };
  return { success: true };
}

/**
 * Insère une discussion directement dans Supabase
 */
export async function insertDiscussionToSupabase(
  data: { title: string; author_name: string; category_slug: string; time_label: string; trending: boolean },
): Promise<SupabaseInsertResult> {
  if (!hasSupabaseEnv || !supabase) {
    return { success: false, error: "Supabase non configuré" };
  }
  const { error } = await supabase.from("forum_discussions").insert({ ...data, replies: 0 });
  if (error) return { success: false, error: error.message };
  return { success: true };
}

/**
 * Synchronise toutes les soumissions approuvées du localStorage vers Supabase
 */
export async function syncApprovedToSupabase() {
  if (!hasSupabaseEnv || !supabase) {
    return { synced: 0, errors: 0, messages: ["Supabase non configuré"] };
  }

  const allSubmissionsKey = "arteia_user_submissions";
  let synced = 0;
  let errors = 0;
  const messages: string[] = [];

  try {
    const raw = localStorage.getItem(allSubmissionsKey);
    if (!raw) return { synced: 0, errors: 0, messages: ["Aucune soumission en localStorage"] };

    const submissions = JSON.parse(raw);
    for (const sub of submissions) {
      if (sub.status !== "approved") continue;

      const data = sub.data || {};

      try {
        let result: SupabaseInsertResult;

        if (sub.type === "artist") {
          result = await insertArtistToSupabase({
            name: data.name || "",
            category_slug: data.category || "music",
            role: data.role || "Artiste",
            image: data.image || "",
            featured_work: data.featuredWork || "Œuvre à venir",
          });
        } else if (sub.type === "artwork") {
          result = await insertArtworkToSupabase({
            title: data.title || "",
            artist_name: data.artist || "Anonyme",
            category_slug: data.category || "music",
            medium: data.medium || "Numérique",
            image: data.image || "",
            height: data.height || "aspect-square",
          });
        } else if (sub.type === "discussion") {
          result = await insertDiscussionToSupabase({
            title: data.title || "",
            author_name: data.author || "Anonyme",
            category_slug: data.category || "music",
            time_label: data.time || "Aujourd'hui",
            trending: data.trending || false,
          });
        } else {
          continue;
        }

        if (result.success) {
          synced++;
          // Marquer comme synchronisé
          sub.status = "synced";
        } else {
          errors++;
          messages.push(`Erreur pour ${sub.id || "inconnu"}: ${result.error}`);
        }
      } catch (e) {
        errors++;
        messages.push(`Exception pour ${sub.id || "inconnu"}: ${e}`);
      }
    }

    // Sauvegarder les statuts mis à jour
    localStorage.setItem(allSubmissionsKey, JSON.stringify(submissions));
  } catch (e) {
    messages.push(`Erreur générale: ${e}`);
  }

  return { synced, errors, messages };
}