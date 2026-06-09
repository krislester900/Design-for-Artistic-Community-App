import type { CategorySlug } from "../data/community";

export type StaticPageId =
  | "home"
  | "music"
  | "visual-art"
  | "manga"
  | "film"
  | "literature"
  | "animation"
  | "community"
  | "database"
  | "login"
  | "signup"
  | "profile"
  | "admin";

export const staticPagePaths: Record<StaticPageId, string> = {
  home: "/index.html",
  music: "/music.html",
  "visual-art": "/art-visuel.html",
  manga: "/manga.html",
  film: "/films.html",
  literature: "/litterature.html",
  animation: "/animation.html",
  community: "/community.html",
  database: "/database.html",
  login: "/connexion.html",
  signup: "/inscription.html",
  profile: "/profil.html",
  admin: "/admin.html",
};

export function getCategoryPagePath(category: Exclude<CategorySlug, "all">) {
  return staticPagePaths[category];
}

export function getStaticPagePath(page: StaticPageId) {
  return staticPagePaths[page];
}

export function openStaticPage(page: StaticPageId) {
  window.location.assign(staticPagePaths[page]);
}

export function openCategoryPage(category: Exclude<CategorySlug, "all">) {
  window.location.assign(getCategoryPagePath(category));
}
