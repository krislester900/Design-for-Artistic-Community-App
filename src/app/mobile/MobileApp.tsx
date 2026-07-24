import { lazy, Suspense, useState, useEffect } from "react";
import { Home, Compass, Menu, MessageCircle, User } from "lucide-react";
import { useCommunityDataQuery } from "../hooks/useCommunityDataQuery";
import { WelcomeBird } from "./WelcomeBird";
import { MobileDrawer } from "./MobileDrawer";

const MobileHome = lazy(() => import("./MobileHome").then(m => ({ default: m.MobileHome })));
const MobileCommunity = lazy(() => import("./MobileCommunity").then(m => ({ default: m.MobileCommunity })));
const MobileUniverse = lazy(() => import("./MobileUniverse").then(m => ({ default: m.MobileUniverse })));
const MobileExplore = lazy(() => import("./MobileExplore").then(m => ({ default: m.MobileExplore })));
const MobileProfile = lazy(() => import("./MobileProfile").then(m => ({ default: m.MobileProfile })));
const MobileNotifications = lazy(() => import("./MobileNotifications").then(m => ({ default: m.MobileNotifications })));
const MobileSearch = lazy(() => import("./MobileSearch").then(m => ({ default: m.MobileSearch })));

type MobileView = "home" | "community" | "universe" | "explore" | "profile" | "notifications" | "search";

export function MobileApp() {
  const [currentView, setCurrentView] = useState<MobileView>("home");
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [showBird, setShowBird] = useState(true);
  const { data } = useCommunityDataQuery();

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

  function renderView() {
    switch (currentView) {
      case "home":
        return <MobileHome />;
      case "community":
        return <MobileCommunity />;
      case "universe":
        return <MobileUniverse slug={currentView} onBack={() => setCurrentView("explore")} />;
      case "explore":
        return <MobileExplore data={data} />;
      case "profile":
        return <MobileProfile />;
      case "notifications":
        return <MobileNotifications />;
      case "search":
        return <MobileSearch />;
      default:
        return <MobileHome />;
    }
  }

  function handleNavigate(view: string) {
    if (view === "home" || view === "community" || view === "universe" || view === "explore" || view === "profile" || view === "notifications" || view === "search") {
      setCurrentView(view);
    }
    setDrawerOpen(false);
  }

  const navItems = [
    { id: "home" as MobileView, label: "Accueil", icon: Home },
    { id: "explore" as MobileView, label: "Explorer", icon: Compass },
    { id: "menu" as const, label: "Menu", icon: Menu },
    { id: "community" as MobileView, label: "Communauté", icon: MessageCircle },
    { id: "profile" as MobileView, label: "Profil", icon: User },
  ];

  return (
    <div className="mobile-app h-full w-full relative overflow-hidden">
      {showBird && <WelcomeBird />}
      <MobileDrawer
        isOpen={drawerOpen}
        activeTab={currentView}
        onNavigate={handleNavigate}
        onClose={() => setDrawerOpen(false)}
      />
      <Suspense fallback={
        <div className="h-full w-full flex items-center justify-center bg-background">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary/30 border-t-primary" />
        </div>
      }>
        <div className="mobile-view h-full w-full">
          {renderView()}
        </div>
      </Suspense>
      <nav className="fixed bottom-0 left-0 right-0 z-40 flex items-center justify-around border-t border-border bg-background/95 backdrop-blur-lg px-2 py-2 safe-area-bottom">
        {navItems.map((item) => {
          const Icon = item.icon;
          if (item.id === "menu") {
            return (
              <button
                key="menu"
                onClick={() => setDrawerOpen(true)}
                className="flex flex-col items-center gap-1 p-2 text-xs text-muted-foreground active:scale-90 transition-all touch-manipulation"
              >
                <Icon className="h-5 w-5" />
                <span>{item.label}</span>
              </button>
            );
          }
          return (
            <button
              key={item.id}
              onClick={() => handleNavigate(item.id)}
              className={`flex flex-col items-center gap-1 p-2 text-xs transition-all active:scale-90 touch-manipulation ${
                currentView === item.id ? "text-primary" : "text-muted-foreground"
              }`}
            >
              <Icon className="h-5 w-5" />
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>
    </div>
  );
}