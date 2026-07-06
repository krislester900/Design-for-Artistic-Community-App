import { MobileHome } from "./MobileHome";
import { MobileCommunity } from "./MobileCommunity";
import { MobileUniverse } from "./MobileUniverse";
import { MobileExplore } from "./MobileExplore";
import { MobileProfile } from "./MobileProfile";
import { MobileNotifications } from "./MobileNotifications";
import { MobileSearch } from "./MobileSearch";
import { MobileDrawer } from "./MobileDrawer";
import { useState, useEffect } from "react";

type MobileView = "home" | "community" | "universe" | "explore" | "profile" | "notifications" | "search";

function WelcomeBird({ onFinish }: { onFinish: () => void }) {
  const [phase, setPhase] = useState<"idle" | "flying" | "gone">("idle");

  useEffect(() => {
    const fly = setTimeout(() => setPhase("flying"), 2500);
    const remove = setTimeout(() => {
      setPhase("gone");
      onFinish();
    }, 3500);
    return () => { clearTimeout(fly); clearTimeout(remove); };
  }, [onFinish]);

  if (phase === "gone") return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-background/60 backdrop-blur-sm">
      <div
        className={`relative ${phase === "flying" ? "animate-bird-fly-away" : "animate-bird-float"}`}
        style={{ animationDuration: phase === "flying" ? "1s" : "2s", animationFillMode: "forwards" }}
      >
        <div className={`${phase === "idle" ? "animate-bird-wiggle" : ""}`} style={{ animationDuration: "0.6s" }}>
          <svg width="120" height="120" viewBox="0 0 120 120" fill="none">
            {/* Body */}
            <ellipse cx="60" cy="65" rx="35" ry="30" fill="#3B82F6" />
            {/* Belly */}
            <ellipse cx="60" cy="72" rx="22" ry="18" fill="#FBBF24" />
            {/* Head */}
            <circle cx="60" cy="38" r="24" fill="#3B82F6" />
            {/* Face */}
            <circle cx="60" cy="40" r="16" fill="#60A5FA" />
            {/* Left eye */}
            <circle cx="50" cy="35" r="5" fill="white" />
            <circle cx="50" cy="35" r="3" fill="#1E3A5F" />
            <circle cx="49" cy="34" r="1" fill="white" />
            {/* Right eye */}
            <circle cx="70" cy="35" r="5" fill="white" />
            <circle cx="70" cy="35" r="3" fill="#1E3A5F" />
            <circle cx="69" cy="34" r="1" fill="white" />
            {/* Beak */}
            <polygon points="60,42 52,48 68,48" fill="#F59E0B" />
            {/* Left wing */}
            <g className={phase === "flying" ? "animate-wing-flap" : ""} style={{ transformOrigin: "35px 55px", animationDuration: "0.3s" }}>
              <ellipse cx="30" cy="55" rx="18" ry="12" fill="#2563EB" transform="rotate(10 30 55)" />
            </g>
            {/* Right wing */}
            <g className={phase === "flying" ? "animate-wing-flap" : ""} style={{ transformOrigin: "85px 55px", animationDuration: "0.3s", animationDelay: "0.1s" }}>
              <ellipse cx="90" cy="55" rx="18" ry="12" fill="#2563EB" transform="rotate(-10 90 55)" />
            </g>
            {/* Feet */}
            <rect x="50" y="90" width="4" height="10" rx="2" fill="#F59E0B" />
            <rect x="66" y="90" width="4" height="10" rx="2" fill="#F59E0B" />
            {/* Tail feathers */}
            <ellipse cx="60" cy="92" rx="14" ry="6" fill="#1D4ED8" />
          </svg>
        </div>
        <p className="text-center mt-4 text-lg font-bold text-blue-600 animate-pulse">
          Bienvenue sur Artéïa !
        </p>
      </div>
    </div>
  );
}

export function MobileApp() {
  const [currentView, setCurrentView] = useState<MobileView>("home");
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [showBird, setShowBird] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => setLoading(false), 500);
    return () => clearTimeout(timer);
  }, []);

  if (loading) {
    return (
      <div className="h-full w-full flex items-center justify-center bg-background">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary/30 border-t-primary" />
      </div>
    );
  }

  const renderView = () => {
    switch (currentView) {
      case "home":
        return <MobileHome />;
      case "community":
        return <MobileCommunity />;
      case "universe":
        return <MobileUniverse />;
      case "explore":
        return <MobileExplore />;
      case "profile":
        return <MobileProfile />;
      case "notifications":
        return <MobileNotifications />;
      case "search":
        return <MobileSearch />;
      default:
        return <MobileHome />;
    }
  };

  const handleNavigate = (view: MobileView) => {
    setCurrentView(view);
    setDrawerOpen(false);
  };

  return (
    <div className="mobile-app h-full w-full relative overflow-hidden">
      {showBird && <WelcomeBird onFinish={() => setShowBird(false)} />}
      <MobileDrawer
        isOpen={drawerOpen}
        activeTab={currentView}
        onNavigate={handleNavigate}
        onClose={() => setDrawerOpen(false)}
      />
      <div className="mobile-view h-full w-full">
        {renderView()}
      </div>
      <nav className="fixed bottom-0 left-0 right-0 z-40 flex items-center justify-around border-t border-border bg-background/95 backdrop-blur-lg px-2 py-2">
        <button onClick={() => handleNavigate("home")} className="flex flex-col items-center gap-1 p-2 text-xs text-muted-foreground">
          <span>Accueil</span>
        </button>
        <button onClick={() => handleNavigate("explore")} className="flex flex-col items-center gap-1 p-2 text-xs text-muted-foreground">
          <span>Explorer</span>
        </button>
        <button onClick={() => setDrawerOpen(true)} className="flex flex-col items-center gap-1 p-2 text-xs text-muted-foreground">
          <span>Menu</span>
        </button>
        <button onClick={() => handleNavigate("community")} className="flex flex-col items-center gap-1 p-2 text-xs text-muted-foreground">
          <span>Communauté</span>
        </button>
        <button onClick={() => handleNavigate("profile")} className="flex flex-col items-center gap-1 p-2 text-xs text-muted-foreground">
          <span>Profil</span>
        </button>
      </nav>
    </div>
  );
}
