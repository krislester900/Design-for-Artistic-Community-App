/**
 * MobileApp — Application mobile native avec bottom tabs
 * Animations fluides, pull-to-refresh, skeleton loading, splash, haptic
 */
import { useState, useEffect, useCallback, useRef } from "react";
import {
  Home,
  Compass,
  MessageCircle,
  User,
  Sparkles,
  Plus,
  Bell,
} from "lucide-react";
import { ArtLoadingScreen } from "../components/ArtLoadingScreen";
import { useCommunityData } from "../hooks/useCommunityData";
import { MobileHome } from "./MobileHome";
import { MobileExplore } from "./MobileExplore";
import { MobileCommunity } from "./MobileCommunity";
import { MobileProfile } from "./MobileProfile";
import { ThemeToggle } from "../components/ui/ThemeToggle";

type Tab = "home" | "explore" | "community" | "profile";

const TABS: { id: Tab; label: string; icon: typeof Home }[] = [
  { id: "home", label: "Accueil", icon: Home },
  { id: "explore", label: "Univers", icon: Compass },
  { id: "community", label: "Communauté", icon: MessageCircle },
  { id: "profile", label: "Profil", icon: User },
];

/** Haptic feedback helper */
function haptic() {
  try {
    (navigator as any).vibrate?.(10);
  } catch {}
}

export function MobileApp() {
  const [activeTab, setActiveTab] = useState<Tab>("home");
  const [isLoading, setIsLoading] = useState(true);
  const [tabDirection, setTabDirection] = useState<"left" | "right">("right");
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [notificationCount] = useState(3); // mock
  const { data, source, isLoading: isDataLoading } = useCommunityData();
  const prevTabRef = useRef<Tab>("home");

  useEffect(() => {
    const timer = setTimeout(() => setIsLoading(false), 2000);
    return () => clearTimeout(timer);
  }, []);

  function switchTab(tab: Tab) {
    haptic();
    const currentIdx = TABS.findIndex(t => t.id === activeTab);
    const newIdx = TABS.findIndex(t => t.id === tab);
    setTabDirection(newIdx > currentIdx ? "right" : "left");
    prevTabRef.current = activeTab;
    setActiveTab(tab);
  }

  async function handleRefresh() {
    setIsRefreshing(true);
    haptic();
    // Reload data by forcing re-render
    await new Promise(r => setTimeout(r, 800));
    setIsRefreshing(false);
  }

  const renderTabContent = useCallback(() => {
    if (isDataLoading) {
      return <SkeletonLoader />;
    }
    const animClass = `animate-tab-enter-${tabDirection}`;
    return (
      <div className={animClass}>
        {activeTab === "home" && <MobileHome data={data} source={source} />}
        {activeTab === "explore" && <MobileExplore data={data} onNavigate={switchTab} />}
        {activeTab === "community" && <MobileCommunity />}
        {activeTab === "profile" && <MobileProfile />}
      </div>
    );
  }, [activeTab, data, source, isDataLoading, tabDirection]);

  if (isLoading) {
    return <ArtLoadingScreen onComplete={() => {}} onFinished={() => setIsLoading(false)} />;
  }

  return (
    <div className="mobile-app flex flex-col h-screen bg-background overflow-hidden relative">
      {/* Animated background pattern */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div className="absolute -top-20 -right-20 h-64 w-64 rounded-full bg-primary/5 blur-3xl animate-pulse" />
        <div className="absolute -bottom-20 -left-20 h-56 w-56 rounded-full bg-accent/5 blur-3xl animate-pulse" style={{ animationDelay: "1s" }} />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-72 w-72 rounded-full bg-secondary/3 blur-3xl" />
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.015)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.015)_1px,transparent_1px)] bg-[size:48px_48px] [mask-image:radial-gradient(ellipse_at_center,black_30%,transparent_70%)]" />
        <div className="absolute top-1/4 left-1/4 h-1.5 w-1.5 rounded-full bg-primary/20 blur-[1px] animate-pulse" style={{ animationDuration: "3s" }} />
        <div className="absolute top-2/3 right-1/3 h-2 w-2 rounded-full bg-accent/20 blur-[1px] animate-pulse" style={{ animationDuration: "4s", animationDelay: "1.5s" }} />
        <div className="absolute top-1/3 right-1/4 h-1 w-1 rounded-full bg-secondary/20 blur-[1px] animate-pulse" style={{ animationDuration: "2.5s", animationDelay: "0.8s" }} />
        <div className="absolute bottom-1/3 left-1/3 h-1.5 w-1.5 rounded-full bg-primary/15 blur-[1px] animate-pulse" style={{ animationDuration: "3.5s", animationDelay: "2s" }} />
      </div>

      {/* Pull to refresh indicator */}
      {isRefreshing && (
        <div className="absolute top-0 left-0 right-0 z-50 flex items-center justify-center py-3 bg-background/95 backdrop-blur-xl border-b border-border/30">
          <div className="h-5 w-5 animate-spin rounded-full border-2 border-primary/30 border-t-primary" />
          <span className="ml-2 text-xs text-primary font-medium">Rafraîchissement...</span>
        </div>
      )}

      <div className="h-[env(safe-area-inset-top)] bg-background shrink-0 relative z-10" />

      {/* Header */}
      <header className="flex items-center justify-between px-5 py-3 bg-background/95 backdrop-blur-xl border-b border-border/30 shrink-0 relative z-10">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-accent shadow-lg shadow-primary/20">
            <Sparkles className="h-4 w-4 text-primary-foreground" />
          </div>
          <span className="text-lg font-bold tracking-wider text-foreground" style={{ fontFamily: "'Alien Block', cursive" }}>
            Artéïa
          </span>
        </div>
        <div className="flex items-center gap-2">
          <ThemeToggle />
          <div className="text-[10px] uppercase tracking-[0.3em] text-muted-foreground/60">
            {TABS.find(t => t.id === activeTab)?.label}
          </div>
        </div>
      </header>

      {/* Main content */}
      <main
        className="flex-1 overflow-y-auto overflow-x-hidden relative z-10"
        style={{ WebkitOverflowScrolling: "touch" }}
        onTouchStart={(e) => {
          // Detect pull-to-refresh
          const target = e.currentTarget;
          if (target.scrollTop <= 0) {
            (target as any)._touchStartY = e.touches[0].clientY;
          }
        }}
        onTouchMove={(e) => {
          const target = e.currentTarget;
          if (target.scrollTop <= 0 && (target as any)._touchStartY) {
            const delta = e.touches[0].clientY - (target as any)._touchStartY;
            if (delta > 80 && !isRefreshing) {
              handleRefresh();
              (target as any)._touchStartY = null;
            }
          }
        }}
      >
        {renderTabContent()}
      </main>

      {/* FAB — Floating Action Button */}
      <button
        onClick={() => { haptic(); switchTab("community"); }}
        className="absolute bottom-20 right-4 z-20 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-accent text-primary-foreground shadow-xl shadow-primary/30 active:scale-90 transition-all duration-200 touch-manipulation animate-bounce-slow"
        aria-label="Créer"
      >
        <Plus className="h-6 w-6" />
      </button>

      {/* Bottom tab bar */}
      <nav className="bottom-nav flex items-center justify-around px-2 pb-[env(safe-area-inset-bottom)] pt-1 bg-background/95 backdrop-blur-xl border-t border-border/30 shrink-0 relative z-10">
        {TABS.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => switchTab(tab.id)}
              className={`relative flex flex-col items-center gap-0.5 py-1 px-3 rounded-xl transition-all duration-200 min-w-[64px] touch-manipulation ${
                isActive
                  ? "text-primary scale-105"
                  : "text-muted-foreground/50 hover:text-muted-foreground"
              }`}
              aria-label={tab.label}
            >
              <div className={`relative flex items-center justify-center h-7 w-7 transition-all ${isActive ? "text-primary" : ""}`}>
                <Icon className="h-5 w-5" strokeWidth={isActive ? 2.5 : 1.5} />
                {isActive && (
                  <div className="absolute -top-0.5 h-1 w-4 rounded-full bg-primary shadow-sm shadow-primary/30 animate-tab-indicator" />
                )}
              </div>
              <span className={`text-[10px] font-medium tracking-wide ${isActive ? "text-primary" : ""}`}>
                {tab.label}
              </span>
              {/* Notification badge */}
              {tab.id === "community" && notificationCount > 0 && (
                <span className="absolute -top-0.5 -right-0.5 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-red-500 text-[9px] font-bold text-white px-1 animate-pulse">
                  {notificationCount}
                </span>
              )}
            </button>
          );
        })}
      </nav>
    </div>
  );
}

/** Skeleton loader for data loading state */
function SkeletonLoader() {
  return (
    <div className="px-4 py-6 space-y-6 animate-pulse">
      {/* Hero skeleton */}
      <div className="h-48 rounded-3xl bg-card/60" />
      {/* Grid skeleton */}
      <div className="grid grid-cols-4 gap-3">
        {[1,2,3,4].map(i => (
          <div key={i} className="flex flex-col items-center gap-2 p-3 rounded-2xl bg-card/60">
            <div className="h-11 w-11 rounded-xl bg-muted/20" />
            <div className="h-3 w-12 rounded-full bg-muted/20" />
          </div>
        ))}
      </div>
      {/* Cards skeleton */}
      <div className="flex gap-3">
        {[1,2,3].map(i => (
          <div key={i} className="w-40 rounded-2xl bg-card/60 overflow-hidden">
            <div className="h-28 bg-muted/20" />
            <div className="p-3 space-y-2">
              <div className="h-3 w-3/4 rounded-full bg-muted/20" />
              <div className="h-2 w-1/2 rounded-full bg-muted/20" />
            </div>
          </div>
        ))}
      </div>
      {/* List skeleton */}
      <div className="rounded-2xl bg-card/60 divide-y divide-border/20 overflow-hidden">
        {[1,2,3,4,5].map(i => (
          <div key={i} className="flex items-center gap-3 px-4 py-3">
            <div className="h-10 w-10 rounded-full bg-muted/20" />
            <div className="flex-1 space-y-1.5">
              <div className="h-3 w-2/3 rounded-full bg-muted/20" />
              <div className="h-2 w-1/2 rounded-full bg-muted/20" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}