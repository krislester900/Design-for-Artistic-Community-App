import type { Artist, Artwork, Discussion } from "../data/community";
import { autoModerator } from "./AutoModerationService";
import { hasSupabaseEnv } from "../lib/supabase";
import {
  insertArtistToSupabase,
  insertArtworkToSupabase,
  insertDiscussionToSupabase,
} from "../services/submission-sync";

/* ───── LocalStorage Mock Store ───── */

const SUBMISSIONS_KEY = "arteia_user_submissions";
const PROFILE_KEY = "arteia_user_profile";

export interface SubmissionItem {
  id: string;
  type: "artist" | "artwork" | "discussion";
  data: Artist | Artwork | Discussion;
  submittedAt: string;
  status: "pending" | "approved" | "rejected";
  userEmail: string;
  qualityScore: number;
  moderationReason: string;
}

export interface UserProfile {
  displayName: string;
  bio: string;
  univers: string[];
  email: string;
  submissions: SubmissionItem[];
}

function getStoredProfile(): UserProfile | null {
  try {
    const raw = localStorage.getItem(PROFILE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function saveProfile(profile: UserProfile) {
  localStorage.setItem(PROFILE_KEY, JSON.stringify(profile));
}

function getAllSubmissions(): SubmissionItem[] {
  try {
    const raw = localStorage.getItem(SUBMISSIONS_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveAllSubmissions(items: SubmissionItem[]) {
  localStorage.setItem(SUBMISSIONS_KEY, JSON.stringify(items));
}

/* ───── Public API ───── */

export function getProfile(): UserProfile | null {
  return getStoredProfile();
}

export function saveUserProfile(profile: Partial<UserProfile> & { email: string }) {
  const existing = getStoredProfile();
  const updated: UserProfile = {
    displayName: profile.displayName || existing?.displayName || "Créateur",
    bio: profile.bio || existing?.bio || "",
    univers: profile.univers || existing?.univers || [],
    email: profile.email,
    submissions: existing?.submissions || [],
  };
  saveProfile(updated);
  return updated;
}

/**
 * Crée une soumission, la modère automatiquement,
 * l'approuve si elle passe les critères du robot,
 * ET l'envoie directement dans Supabase si disponible.
 */
function createSubmission(params: {
  type: SubmissionItem["type"];
  data: Artist | Artwork | Discussion;
  title: string;
  description?: string;
  imageUrl?: string;
  category?: string;
  userEmail: string;
}): SubmissionItem {
  // Auto-moderation
  const moderation = autoModerator.moderate({
    title: params.title,
    description: params.description,
    imageUrl: params.imageUrl,
    category: params.category,
  });

  const qualityScore = autoModerator.calculateQualityScore({
    title: params.title,
    description: params.description,
    imageUrl: params.imageUrl,
  });

  const submission: SubmissionItem = {
    id: crypto.randomUUID(),
    type: params.type,
    data: params.data,
    submittedAt: new Date().toISOString(),
    status: moderation.approved ? "approved" : "pending",
    userEmail: params.userEmail,
    qualityScore,
    moderationReason: moderation.reason,
  };

  // Store globally in localStorage
  const all = getAllSubmissions();
  all.push(submission);
  saveAllSubmissions(all);

  // Store in user profile
  const profile = getStoredProfile();
  if (profile) {
    profile.submissions.push(submission);
    saveProfile(profile);
  }

  // Si Supabase est configuré ET la soumission est approuvée,
  // on l'envoie directement dans la base
  if (hasSupabaseEnv && moderation.approved) {
    const data = params.data as any;
    // Déclencher l'insertion sans bloquer (fire-and-forget)
    syncToSupabase(submission, data);
  }

  return submission;
}

/**
 * Envoie une soumission approuvée directement dans Supabase
 */
async function syncToSupabase(submission: SubmissionItem, data: any) {
  try {
    let result;
    if (submission.type === "artist") {
      result = await insertArtistToSupabase({
        name: data.name || "",
        category_slug: data.category || "music",
        role: data.role || "Artiste",
        image: data.image || "",
        featured_work: data.featuredWork || "Œuvre à venir",
      });
    } else if (submission.type === "artwork") {
      result = await insertArtworkToSupabase({
        title: data.title || "",
        artist_name: data.artist || "Anonyme",
        category_slug: data.category || "music",
        medium: data.medium || "Numérique",
        image: data.image || "",
        height: data.height || "aspect-square",
      });
    } else if (submission.type === "discussion") {
      result = await insertDiscussionToSupabase({
        title: data.title || "",
        author_name: data.author || "Anonyme",
        category_slug: data.category || "music",
        time_label: data.time || "Aujourd'hui",
        trending: data.trending || false,
      });
    }

    if (result && result.success) {
      console.log(`[Sync] Soumission ${submission.id} envoyée à Supabase avec succès.`);
      // Marquer comme synchronisé
      const all = getAllSubmissions();
      const idx = all.findIndex((s) => s.id === submission.id);
      if (idx !== -1) {
        all[idx].status = "synced" as any;
        saveAllSubmissions(all);
      }
    } else if (result && result.error) {
      console.warn(`[Sync] Échec pour ${submission.id}: ${result.error}`);
    }
  } catch (e) {
    console.warn(`[Sync] Erreur pour ${submission.id}:`, e);
  }
}

export function submitArtwork(
  artwork: { title: string; artist: string; category: string; medium: string; image: string; height: string },
  userEmail: string,
): SubmissionItem {
  return createSubmission({
    type: "artwork",
    data: { ...artwork, likes: 0, views: 0 } as unknown as Artwork,
    title: artwork.title,
    description: artwork.medium,
    imageUrl: artwork.image,
    category: artwork.category,
    userEmail,
  });
}

export function submitArtistProfile(
  artist: { name: string; category: string; role: string; image: string; featuredWork: string },
  userEmail: string,
): SubmissionItem {
  return createSubmission({
    type: "artist",
    data: { ...artist, likes: 0 } as unknown as Artist,
    title: artist.name,
    description: artist.role,
    imageUrl: artist.image,
    category: artist.category,
    userEmail,
  });
}

export function submitDiscussion(
  discussion: { title: string; author: string; category: string; time: string; trending: boolean },
  userEmail: string,
): SubmissionItem {
  return createSubmission({
    type: "discussion",
    data: { ...discussion, replies: 0 } as unknown as Discussion,
    title: discussion.title,
    description: discussion.title,
    imageUrl: undefined,
    category: discussion.category,
    userEmail,
  });
}

export function getUserSubmissions(userEmail: string): SubmissionItem[] {
  return getAllSubmissions().filter((s) => s.userEmail === userEmail);
}

export function getAllPendingSubmissions(): SubmissionItem[] {
  return getAllSubmissions().filter((s) => s.status === "pending");
}

export function approveSubmission(id: string) {
  const all = getAllSubmissions();
  const idx = all.findIndex((s) => s.id === id);
  if (idx !== -1) {
    all[idx].status = "approved";
    saveAllSubmissions(all);
    // Tenter de synchroniser vers Supabase
    const sub = all[idx];
    if (sub && hasSupabaseEnv) {
      syncToSupabase(sub, sub.data);
    }
  }
}

export function rejectSubmission(id: string) {
  const all = getAllSubmissions();
  const idx = all.findIndex((s) => s.id === id);
  if (idx !== -1) {
    all[idx].status = "rejected";
    saveAllSubmissions(all);
  }
}

export function loadApprovedContent() {
  const approved = getAllSubmissions().filter((s) => s.status === "approved");
  return { submissions: approved };
}