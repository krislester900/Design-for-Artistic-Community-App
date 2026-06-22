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

let riveOverlay: HTMLDivElement | null = null;

function showRiveTransition(onDone: () => void) {
  if (riveOverlay) return;

  riveOverlay = document.createElement("div");
  riveOverlay.style.cssText = `
    position: fixed; inset: 0; z-index: 99999;
    display: flex; align-items: center; justify-content: center;
    background: #0a0a0a;
  `;

  const canvas = document.createElement("canvas");
  canvas.style.cssText = "width: 100%; height: 100%; max-width: 600px; max-height: 600px;";
  riveOverlay.appendChild(canvas);
  document.body.appendChild(riveOverlay);

  const cleanup = () => {
    if (riveOverlay) {
      riveOverlay.remove();
      riveOverlay = null;
    }
  };

  const loadRive = async () => {
    try {
      // Import @rive-app/canvas which has the Rive constructor
      const canvasModule = await import("@rive-app/canvas");
      const Rive = canvasModule.Rive || (canvasModule as any).default?.Rive;
      
      if (Rive && typeof Rive === "function") {
        const instance = new Rive({
          src: "/animations/cloudy-walk.riv",
          canvas,
          autoplay: true,
        });
        
        setTimeout(() => {
          if (typeof instance.cleanup === "function") instance.cleanup();
          cleanup();
          onDone();
        }, 1500);
        return;
      }
    } catch (err) {
      console.warn("Rive animation fallback:", err);
    }
    
    // Fallback
    setTimeout(() => {
      cleanup();
      onDone();
    }, 800);
  };

  loadRive();
}

export function openStaticPage(page: StaticPageId) {
  const currentPage = document.body.dataset.page as StaticPageId | undefined;
  const isFromMusicOrCommunity = currentPage === "music" || currentPage === "community";
  const isToMusicOrCommunity = page === "music" || page === "community";

  // Show Rive transition when navigating between music and community
  if (isFromMusicOrCommunity && isToMusicOrCommunity && currentPage !== page) {
    showRiveTransition(() => {
      window.location.assign(staticPagePaths[page]);
    });
  } else {
    window.location.assign(staticPagePaths[page]);
  }
}

export function openCategoryPage(category: Exclude<CategorySlug, "all">) {
  openStaticPage(category);
}