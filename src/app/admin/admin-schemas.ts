import { z } from "zod";

export const artistSchema = z.object({
  name: z.string().min(1, "Le nom est requis"),
  category_slug: z.string().min(1, "La catégorie est requise"),
  role: z.string().min(1, "Le rôle est requis"),
  image: z.string().min(1, "L'image est requise").refine(
    (val) => val.startsWith("http://") || val.startsWith("https://") || val.startsWith("/"),
    { message: "L'URL de l'image doit être valide" }
  ),
  featured_work: z.string().min(1, "L'œuvre mise en avant est requise"),
});

export const artworkSchema = z.object({
  title: z.string().min(1, "Le titre est requis"),
  artist_name: z.string().min(1, "Le nom de l'artiste est requis"),
  category_slug: z.string().min(1, "La catégorie est requise"),
  medium: z.string().min(1, "Le médium est requis"),
  image: z.string().min(1, "L'image est requise").refine(
    (val) => val.startsWith("http://") || val.startsWith("https://") || val.startsWith("/"),
    { message: "L'URL de l'image doit être valide" }
  ),
  height: z.string().min(1, "Le format est requis"),
});

export const discussionSchema = z.object({
  title: z.string().min(1, "Le titre est requis"),
  author_name: z.string().min(1, "L'auteur est requis"),
  category_slug: z.string().min(1, "La catégorie est requise"),
  time_label: z.string().min(1, "Le label temps est requis"),
  trending: z.boolean(),
});

export const trendSchema = z.object({
  tag: z.string().min(1, "Le tag est requis").max(50, "Le tag est trop long"),
  category_slug: z.string().min(1, "La catégorie est requise"),
  sort_order: z.number().min(0, "L'ordre doit être positif"),
});

export const eventSchema = z.object({
  title: z.string().min(1, "Le titre est requis"),
  date_label: z.string().min(1, "La date est requise"),
  category_slug: z.string().min(1, "La catégorie est requise"),
  sort_order: z.number().min(0, "L'ordre doit être positif"),
});

export const statSchema = z.object({
  label: z.string().min(1, "Le label est requis"),
  number_label: z.string().min(1, "La valeur est requise"),
  sort_order: z.number().min(0, "L'ordre doit être positif"),
});

export const loginSchema = z.object({
  email: z.string().email("L'email n'est pas valide").min(1, "L'email est requis"),
  password: z.string().min(6, "Le mot de passe doit contenir au moins 6 caractères"),
});

export type ArtistForm = z.infer<typeof artistSchema>;
export type ArtworkForm = z.infer<typeof artworkSchema>;
export type DiscussionForm = z.infer<typeof discussionSchema>;
export type TrendForm = z.infer<typeof trendSchema>;
export type EventForm = z.infer<typeof eventSchema>;
export type StatForm = z.infer<typeof statSchema>;
export type LoginForm = z.infer<typeof loginSchema>;
