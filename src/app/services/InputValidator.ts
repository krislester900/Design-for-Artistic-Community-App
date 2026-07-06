import { z } from "zod";

/* ───── Input Validation Schemas ───── */

export const ChatMessageSchema = z.object({
  content: z
    .string()
    .trim()
    .min(1, "Message vide")
    .max(5000, "Message trop long (max 5000 caractères)")
    .refine(
      (val) => !val.includes("<script"),
      "Contenu malveillant détecté: scripts non autorisés",
    )
    .refine(
      (val) => !val.includes("eval("),
      "Contenu malveillant détecté: eval non autorisé",
    )
    .refine(
      (val) => !val.includes("onclick="),
      "Contenu malveillant détecté: event handlers non autorisés",
    ),
  role: z.enum(["user", "assistant", "system"]),
});

export type ChatMessage = z.infer<typeof ChatMessageSchema>;

export const ArtworkInputSchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, "Titre requis")
    .max(200, "Titre trop long"),
  artist: z
    .string()
    .trim()
    .min(1, "Artiste requis")
    .max(100, "Nom artiste trop long"),
  category: z.string().min(1, "Catégorie requise"),
  medium: z
    .string()
    .trim()
    .min(1, "Médium requis")
    .max(100, "Médium trop long"),
  image: z.string().url("URL image invalide"),
  height: z.string().min(1, "Hauteur requise"),
});

export type ArtworkInput = z.infer<typeof ArtworkInputSchema>;

export const ArtistInputSchema = z.object({
  name: z
    .string()
    .trim()
    .min(1, "Nom requis")
    .max(100, "Nom trop long"),
  category: z.string().min(1, "Catégorie requise"),
  role: z
    .string()
    .trim()
    .min(1, "Rôle requis")
    .max(100, "Rôle trop long"),
  image: z.string().url("URL image invalide"),
  featuredWork: z
    .string()
    .trim()
    .min(1, "Œuvre requise")
    .max(200, "Œuvre trop longue"),
});

export type ArtistInput = z.infer<typeof ArtistInputSchema>;

export const DiscussionInputSchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, "Titre requis")
    .max(200, "Titre trop long"),
  author: z
    .string()
    .trim()
    .min(1, "Auteur requis")
    .max(100, "Nom auteur trop long"),
  category: z.string().min(1, "Catégorie requise"),
  time: z
    .string()
    .trim()
    .min(1, "Temps requis")
    .max(100, "Temps trop long"),
  trending: z.boolean(),
});

export type DiscussionInput = z.infer<typeof DiscussionInputSchema>;

/* ───── Text Sanitization ───── */

/**
 * Sanitize text by removing dangerous characters and patterns
 */
export function sanitizeText(text: string): string {
  return text
    .replace(/<script[^>]*>.*?<\/script>/gi, "") // Remove script tags
    .replace(/on\w+\s*=/gi, "") // Remove event handlers
    .replace(/javascript:/gi, "") // Remove javascript: protocol
    .trim();
}

/**
 * Sanitize HTML by escaping dangerous characters
 */
export function escapeHtml(text: string): string {
  const map: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;",
  };
  return text.replace(/[&<>"']/g, (char) => map[char] || char);
}

/**
 * Validate email format
 */
export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/* ───── Public Validation Functions ───── */

export function validateChatMessage(message: unknown): ChatMessage {
  try {
    return ChatMessageSchema.parse(message);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errorMsg = error.errors
        .map((e) => `${e.path.join(".")}: ${e.message}`)
        .join("; ");
      console.error("[Validation] Chat message invalide:", errorMsg);
      throw new Error(`Message invalide: ${errorMsg}`);
    }
    throw error;
  }
}

export function validateArtworkInput(artwork: unknown): ArtworkInput {
  try {
    const data = ArtworkInputSchema.parse(artwork);
    return {
      ...data,
      title: sanitizeText(data.title),
      artist: sanitizeText(data.artist),
      medium: sanitizeText(data.medium),
    };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errorMsg = error.errors
        .map((e) => `${e.path.join(".")}: ${e.message}`)
        .join("; ");
      console.error("[Validation] Artwork invalide:", errorMsg);
      throw new Error(`Œuvre invalide: ${errorMsg}`);
    }
    throw error;
  }
}

export function validateArtistInput(artist: unknown): ArtistInput {
  try {
    const data = ArtistSchema.parse(artist);
    return {
      ...data,
      name: sanitizeText(data.name),
      role: sanitizeText(data.role),
      featuredWork: sanitizeText(data.featuredWork),
    };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errorMsg = error.errors
        .map((e) => `${e.path.join(".")}: ${e.message}`)
        .join("; ");
      console.error("[Validation] Artiste invalide:", errorMsg);
      throw new Error(`Artiste invalide: ${errorMsg}`);
    }
    throw error;
  }
}

export function validateDiscussionInput(discussion: unknown): DiscussionInput {
  try {
    const data = DiscussionInputSchema.parse(discussion);
    return {
      ...data,
      title: sanitizeText(data.title),
      author: sanitizeText(data.author),
      time: sanitizeText(data.time),
    };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errorMsg = error.errors
        .map((e) => `${e.path.join(".")}: ${e.message}`)
        .join("; ");
      console.error("[Validation] Discussion invalide:", errorMsg);
      throw new Error(`Discussion invalide: ${errorMsg}`);
    }
    throw error;
  }
}

/* ───── Utility Functions ───── */

export function processUserInput(raw: string, maxLength: number = 5000): string {
  if (raw.length > maxLength) {
    console.warn(
      `[Input] Message trop long: ${raw.length} > ${maxLength}`,
    );
    return sanitizeText(raw.substring(0, maxLength));
  }

  return sanitizeText(raw);
}

export function isValidUrl(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

export function validateUUID(id: string): boolean {
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(id);
}
