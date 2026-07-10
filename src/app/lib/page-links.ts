import type { CategorySlug } from "../data/community";

type StaticPageId =
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
  | "admin"
  | "ontology"
  | "inbox";

const staticPagePaths: Record<StaticPageId, string> = {
  home: "/",
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
  ontology: "/#/ontology",
  inbox: "/#/inbox",
};

export function getCategoryPagePath(category: Exclude<CategorySlug, "all">) {
  return staticPagePaths[category];
}

export function getStaticPagePath(page: StaticPageId) {
  return staticPagePaths[page];
}

let riveOverlay: HTMLDivElement | null = null;

/* ───── Rive Module Types ───── */

interface RiveConfig {
  src: string;
  canvas: HTMLCanvasElement;
  autoplay: boolean;
}

interface RiveInstance {
  cleanup?: () => void;
}

interface RiveModuleType {
  Rive: new (config: RiveConfig) => RiveInstance;
}

/* ───── Safe Rive Module Loading ───── */

async function loadRiveModule(): Promise<RiveModuleType | null> {
  const timeoutPromise = new Promise<null>((resolve) => {
    setTimeout(() => {
      console.warn("[Rive] Module loading timeout (5s)");
      resolve(null);
    }, 5000);
  });

  const loadPromise = (async (): Promise<RiveModuleType | null> => {
    try {
      const imported = await import("@rive-app/canvas");

      if (!imported || typeof imported !== "object") {
        console.warn("[Rive] Module import returned invalid type");
        return null;
      }

      const mod = imported as Record<string, unknown>;

      // ✅ Type-safe constructor lookup
      let RiveConstructor: unknown = mod.Rive;

      // Fallback to default export if needed
      if (typeof RiveConstructor !== "function" && mod.default) {
        const defaultExport = mod.default as Record<string, unknown>;
        RiveConstructor = defaultExport.Rive;
      }

      if (typeof RiveConstructor !== "function") {
        console.warn("[Rive] Rive constructor not found in module");
        return null;
      }

      return {
        Rive: RiveConstructor as new (config: RiveConfig) => RiveInstance,
      };
    } catch (error) {
      console.warn("[Rive] Module loading error:", error);
      return null;
    }
  })();

  return Promise.race([loadPromise, timeoutPromise]);
}

function showRiveTransition(onDone: () => void) {
  if (riveOverlay) return;

  const cleanup = () => {
    if (riveOverlay) {
      riveOverlay.remove();
      riveOverlay = null;
    }
  };

  const fallbackTimeout = setTimeout(() => {
    cleanup();
    onDone();
  }, 2000);

  loadRiveModule()
    .then((riveModule) => {
      if (!riveModule) {
        clearTimeout(fallbackTimeout);
        cleanup();
        onDone();
        return;
      }

      riveOverlay = document.createElement("div");
      riveOverlay.style.cssText = `
        position: fixed; inset: 0; z-index: 99999;
        display: flex; align-items: center; justify-content: center;
        background: #0a0a0a;
      `;

      const canvas = document.createElement("canvas");
      canvas.style.cssText =
        "width: 100%; height: 100%; max-width: 600px; max-height: 600px;";
      riveOverlay.appendChild(canvas);
      document.body.appendChild(riveOverlay);

      try {
        const instance = new riveModule.Rive({
          src: "/animations/cloudy-walk.riv",
          canvas,
          autoplay: true,
        });

        clearTimeout(fallbackTimeout);
        setTimeout(() => {
          // ✅ Type-safe cleanup call
          if (instance && typeof instance.cleanup === "function") {
            instance.cleanup();
          }
          cleanup();
          onDone();
        }, 1500);
      } catch (err) {
        console.error("[Rive] Instance creation error:", err);
        clearTimeout(fallbackTimeout);
        cleanup();
        onDone();
      }
    })
    .catch((error) => {
      console.error("[Rive] Module loading error:", error);
      clearTimeout(fallbackTimeout);
      cleanup();
      onDone();
    });
}

export function openStaticPage(page: StaticPageId) {
  // If we are inside the SPA (index.html with HashRouter), use hash navigation
  // to avoid full page reloads. Otherwise fall back to the static HTML file.
  const path = window.location.pathname;
  const isInSpa = path.endsWith("/index.html") || path === "/" || path === "";

  if (isInSpa) {
    const route = page === "home" ? "/" : `/${page}`;
    window.location.hash = `#${route}`;
    return;
  }

  const currentPage = document.body.dataset.page as StaticPageId | undefined;
  const isFromMusicOrCommunity =
    currentPage === "music" || currentPage === "community";
  const isToMusicOrCommunity = page === "music" || page === "community";

  // Show Rive transition when navigating between music and community
  if (
    isFromMusicOrCommunity &&
    isToMusicOrCommunity &&
    currentPage !== page
  ) {
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
