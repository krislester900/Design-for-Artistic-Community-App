import { MobileHome } from "./MobileHome";
import { MobileCommunity } from "./MobileCommunity";
import { MobileUniverse } from "./MobileUniverse";
import { MobileExplore } from "./MobileExplore";
import { MobileProfile } from "./MobileProfile";
import { MobileNotifications } from "./MobileNotifications";
import { MobileSearch } from "./MobileSearch";
import { MobileDrawer } from "./MobileDrawer";
import { useState } from "react";

type MobileView = "home" | "community" | "universe" | "explore" | "profile" | "notifications" | "search";

export function MobileApp() {
  const [currentView, setCurrentView] = useState<MobileView>("home");
  const [drawerOpen, setDrawerOpen] = useState(false);

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
      {drawerOpen && (
        <MobileDrawer
          currentView={currentView}
          onNavigate={handleNavigate}
          onClose={() => setDrawerOpen(false)}
        />
      )}
      <div className="mobile-view h-full w-full">
        {renderView()}
      </div>
      {/* Navigation bottom bar */}
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