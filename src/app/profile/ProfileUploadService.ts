import type { Artist, Artwork, Discussion } from "../data/community";
import { autoModerator } from "./AutoModerationService";
import { hasSupabaseEnv } from "../lib/supabase";
import {
  insertArtistToSupabase,
  insertArtworkToSupabase,
  insertDiscussionToSupabase,
} from "../services/submission-sync";
import { z } from "zod";

/* ───── Validation Schemas ───── */

const ArtworkSchema = z.object({
  title: z.string().min(1, "Titre requis"),
  artist: z.string().min(1, "Artiste requis"),
  category: z.string().min(1, "Catégorie requise"),
  medium: z.string().min(1, "Médium requis"),
  image: z.string().url("URL image invalide"),
  height: z.string().min(1),
});

const ArtistSchema = z.object({
  name: z.string().min(1, "Nom requis"),
  category: z.string().min(1, "Catégorie requise"),
  role: z.string().min(1, "Rôle requis"),
  image: z.string().url("URL image invalide"),
  featuredWork: z.string().min(1),
});

const DiscussionSchema = z.object({
  title: z.string().min(1, "Titre requis"),
  author: z.string().min(1, "Auteur requis"),
  category: z.string().min(1, "Catégorie requise"),
  time: z.string().min(1),
  trending: z.boolean(),
});

/* ───── Type Guards ───── */

function isArtwork(data: Artist | Artwork | Discussion): data is Artwork {
  return "title" in data && "medium" in data && "artist" in data;
}

function isArtist(data: Artist | Artwork | Discussion): data is Artist {
  return "name" in data && "role" in data && "featuredWork" in data;
}

function isDiscussion(data: Artist | Artwork | Discussion): data is Discussion {
  return "author" in data && "replies" in data;
}

/* ───── LocalStorage Mock Store ───── */

const SUBMISSIONS_KEY = "arteia_user_submissions";
const PROFILE_KEY = "arteia_user_profile";

export interface SubmissionItem {
  id: string;
  type: "artist" | "artwork" | "discussion";
  data: Artist | Artwork | Discussion;
  submittedAt: string;
  status: "pending" | "approved" | "rejected" | "synced";
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
  } catch (error) {
    console.error("[Profile] Erreur localStorage:", error);
    return null;
  }
}

function saveProfile(profile: UserProfile): boolean {
  try {
    localStorage.setItem(PROFILE_KEY, JSON.stringify(profile));
    return true;
  } catch (error) {
    console.error("[Profile] Erreur sauvegarde:", error);
    return false;
  }
}

function getAllSubmissions(): SubmissionItem[] {
  try {
    const raw = localStorage.getItem(SUBMISSIONS_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch (error) {
    console.error("[Submissions] Erreur lecture:", error);
    return [];
  }
}

function saveAllSubmissions(items: SubmissionItem[]): boolean {
  try {
    localStorage.setItem(SUBMISSIONS_KEY, JSON.stringify(items));
    return true;
  } catch (error) {
    console.error("[Submissions] Erreur sauvegarde:", error);
    return false;
  }
}

/* ───── Sync with Retry Logic ───── */

interface SyncResult {
  success: boolean;
  error?: string;
}

const MAX_RETRIES = 3;
const RETRY_DELAYS = [1000, 5000, 30000];

async function syncToSupabaseWithRetry(
  submission: SubmissionItem,
  data: Artist | Artwork | Discussion,
  retryCount: number = 0,
): Promise<SyncResult> {
  try {
    let result;

    // ✅ Type guards stricts - pas de casting
    if (isArtist(data)) {
      result = await insertArtistToSupabase({
        name: data.name || "",
        category_slug: data.category || "music",
        role: data.role || "Artiste",
        image: data.image || "",
        featured_work: data.featuredWork || "Œuvre à venir",
      });
    } else if (isArtwork(data)) {
      result = await insertArtworkToSupabase({
        title: data.title || "",
        artist_name: data.artist || "Anonyme",
        category_slug: data.category || "music",
        medium: data.medium || "Numérique",
        image: data.image || "",
        height: data.height || "aspect-square",
      });
    } else if (isDiscussion(data)) {
      result = await insertDiscussionToSupabase({
        title: data.title || "",
        author_name: data.author || "Anonyme",
        category_slug: data.category || "music",
        time_label: data.time || "Aujourd'hui",
        trending: data.trending || false,
      });
    } else {
      return { success: false, error: "Type de données inconnu" };
    }

    if (!result) {
      return { success: false, error: "Résultat vide" };
    }

    if (result.success) {
      console.log(`[Sync] Soumission ${submission.id} synchronisée.`);

      const all = getAllSubmissions();
      const idx = all.findIndex((s) => s.id === submission.id);

      if (idx !== -1) {
        // ✅ Update avec typage explicite
        const updated: SubmissionItem = { ...all[idx], status: "synced" };
        all[idx] = updated;

        if (!saveAllSubmissions(all)) {
          console.warn("[Sync] Erreur sauvegarde status synced");
        }
      }
      return { success: true };
    } else if (result.error) {
      const errorMsg = typeof result.error === "string" ? result.error : String(result.error);
      console.warn(`[Sync] Échec ${submission.id}: ${errorMsg}`);

      // Retry logic
      if (retryCount < MAX_RETRIES) {
        const delay = RETRY_DELAYS[retryCount];
        console.info(`[Sync] Retry ${retryCount + 1}/${MAX_RETRIES} dans ${delay}ms`);
        
        await new Promise((resolve) => setTimeout(resolve, delay));
        return syncToSupabaseWithRetry(submission, data, retryCount + 1);
      }

      return { success: false, error: errorMsg };
    }

    return { success: false, error: "Erreur inconnue" };
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error(`[Sync] Erreur ${submission.id}:`, error);

    // Retry on network errors
    if (retryCount < MAX_RETRIES) {
      const delay = RETRY_DELAYS[retryCount];
      console.info(`[Sync] Retry ${retryCount + 1}/${MAX_RETRIES} après erreur`);
      
      await new Promise((resolve) => setTimeout(resolve, delay));
      return syncToSupabaseWithRetry(submission, data, retryCount + 1);
    }

    return { success: false, error: errorMsg };
  }
}

interface SubmissionParams {
  type: SubmissionItem["type"];
  data: Artist | Artwork | Discussion;
  title: string;
  description?: string;
  imageUrl?: string;
  category?: string;
  userEmail: string;
}

/* ───── Public API ───── */

function createSubmission(params: SubmissionParams): SubmissionItem {
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

  const all = getAllSubmissions();
  all.push(submission);

  if (!saveAllSubmissions(all)) {
    console.error("[Submission] Erreur sauvegarde submissions");
  }

  const profile = getStoredProfile();
  if (profile) {
    profile.submissions.push(submission);
    if (!saveProfile(profile)) {
      console.error("[Submission] Erreur sauvegarde profile");
    }
  }

  // ✅ Sync with proper error handling and retry
  if (hasSupabaseEnv && moderation.approved) {
    syncToSupabaseWithRetry(submission, params.data).catch((error) => {
      console.error(`[Sync] Erreur critique pour ${submission.id}:`, error);
    });
  }

  return submission;
}

export function submitArtwork(
  artwork: {
    title: string;
    artist: string;
    category: string;
    medium: string;
    image: string;
    height: string;
  },
  userEmail: string,
): SubmissionItem {
  // ✅ Validation stricte avec Zod
  const validated = ArtworkSchema.parse(artwork);

  return createSubmission({
    type: "artwork",
    data: {
      ...validated,
      likes: 0,
      views: 0,
    } as Artwork,
    title: validated.title,
    description: validated.medium,
    imageUrl: validated.image,
    category: validated.category,
    userEmail,
  });
}

export function submitArtistProfile(
  artist: {
    name: string;
    category: string;
    role: string;
    image: string;
    featuredWork: string;
  },
  userEmail: string,
): SubmissionItem {
  const validated = ArtistSchema.parse(artist);

  return createSubmission({
    type: "artist",
    data: {
      ...validated,
      likes: 0,
    } as Artist,
    title: validated.name,
    description: validated.role,
    imageUrl: validated.image,
    category: validated.category,
    userEmail,
  });
}

export function submitDiscussion(
  discussion: {
    title: string;
    author: string;
    category: string;
    time: string;
    trending: boolean;
  },
  userEmail: string,
): SubmissionItem {
  const validated = DiscussionSchema.parse(discussion);

  return createSubmission({
    type: "discussion",
    data: {
      ...validated,
      replies: 0,
    } as Discussion,
    title: validated.title,
    description: validated.title,
    imageUrl: undefined,
    category: validated.category,
    userEmail,
  });
}

export function getUserSubmissions(userEmail: string): SubmissionItem[] {
  return getAllSubmissions().filter((s) => s.userEmail === userEmail);
}

export function getAllPendingSubmissions(): SubmissionItem[] {
  return getAllSubmissions().filter((s) => s.status === "pending");
}

export function approveSubmission(id: string): boolean {
  const all = getAllSubmissions();
  const idx = all.findIndex((s) => s.id === id);

  if (idx === -1) {
    console.warn(`[Approve] Soumission ${id} non trouvée`);
    return false;
  }

  const updated: SubmissionItem = { ...all[idx], status: "approved" };
  all[idx] = updated;

  if (!saveAllSubmissions(all)) {
    console.error("[Approve] Erreur sauvegarde");
    return false;
  }

  const sub = all[idx];
  if (sub && hasSupabaseEnv) {
    syncToSupabaseWithRetry(sub, sub.data).catch((error) => {
      console.error("[Approve] Erreur sync:", error);
    });
  }

  return true;
}

export function rejectSubmission(id: string): boolean {
  const all = getAllSubmissions();
  const idx = all.findIndex((s) => s.id === id);

  if (idx === -1) {
    console.warn(`[Reject] Soumission ${id} non trouvée`);
    return false;
  }

  const updated: SubmissionItem = { ...all[idx], status: "rejected" };
  all[idx] = updated;

  return saveAllSubmissions(all);
}

export function loadApprovedContent(): {
  submissions: SubmissionItem[];
} {
  const approved = getAllSubmissions().filter(
    (s) => s.status === "approved" || s.status === "synced",
  );
  return { submissions: approved };
}

export function getProfile(): UserProfile | null {
  return getStoredProfile();
}

export function saveUserProfile(
  profile: Partial<UserProfile> & { email: string },
): UserProfile {
  const existing = getStoredProfile();
  const updated: UserProfile = {
    displayName: profile.displayName || existing?.displayName || "Créateur",
    bio: profile.bio || existing?.bio || "",
    univers: profile.univers || existing?.univers || [],
    email: profile.email,
    submissions: existing?.submissions || [],
  };

  if (!saveProfile(updated)) {
    console.error("[SaveProfile] Erreur persistance");
  }

  return updated;
}
