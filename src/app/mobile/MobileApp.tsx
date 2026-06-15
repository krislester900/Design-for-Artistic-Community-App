/**
 * MobileApp — Application mobile native avec bottom tabs
 * Optimisée pour Capacitor/APK avec navigation tactile
 */
import { useState, useEffect, useCallback } from "react";
import {
  Home,
  Compass,
  MessageCircle,
  User,
  Sparkles,
} from "lucide-react";
import { ArtLoadingScreen } from "../components/ArtLoadingScreen";
import { MobileHome } from "./MobileHome";
import { MobileExplore } from "./MobileExplore";
import { MobileCommunity } from "./MobileCommunity";
import { MobileProfile } from "./MobileProfile";

type Tab = "home" | "explore" | "community" | "profile";

const TABS: { id: Tab; label: string; icon: typeof Home }[] = [
  { id: "home", label: "Accueil", icon: Home },
  { id: "explore", label: "Univers", icon: Compass },
  { id: "community", label: "Communauté", icon: MessageCircle },
  { id: "profile", label: "Profil", icon: User },
];

export function MobileApp() {
  const [activeTab, setActiveTab] = useState<Tab>("home");
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Minimum 1.5s loading screen
    const timer = setTimeout(() => setIsLoading(false), 1800);
    return () => clearTimeout(timer);
  }, []);

  const renderTabContent = useCallback(() => {
    switch (activeTab) {
      case "home": return <MobileHome />;
      case "explore": return <MobileExplore />;
      case "community": return <MobileCommunity />;
      case "profile": return <MobileProfile />;
    }
  }, [activeTab]);

  if (isLoading) {
    return <ArtLoadingScreen onFinished={() => setIsLoading(false)} />;
  }

  return (
    <div className="mobile-app flex flex-col h-screen bg-background overflow-hidden">
      {/* Status bar spacer (for notch) */}
      <div className="h-[env(safe-area-inset-top)] bg-background shrink-0" />

      {/* Header */}
      <header className="flex items-center justify-between px-5 py-3 bg-background/95 backdrop-blur-xl border-b border-border/30 shrink-0">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-accent shadow-lg shadow-primary/20">
            <Sparkles className="h-4 w-4 text-primary-foreground" />
          </div>
          <span className="text-lg font-bold tracking-wider text-foreground" style={{ fontFamily: "'Alien Block', cursive" }}>
            Artéïa
          </span>
        </div>
        <div className="text-[10px] uppercase tracking-[0.3em] text-muted-foreground/60">
          {TABS.find(t => t.id === activeTab)?.label}
        </div>
      </header>

      {/* Main content */}
      <main className="flex-1 overflow-y-auto overflow-x-hidden" style={{ WebkitOverflowScrolling: "touch" }}>
        <div className="animate-fade-in">
          {renderTabContent()}
        </div>
      </main>

      {/* Bottom tab bar */}
      <nav className="bottom-nav flex items-center justify-around px-2 pb-[env(safe-area-inset-bottom)] pt-1 bg-background/95 backdrop-blur-xl border-t border-border/30 shrink-0">
        {TABS.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex flex-col items-center gap-0.5 py-1 px-3 rounded-xl transition-all duration-200 min-w-[64px] touch-manipulation ${
                isActive
                  ? "text-primary scale-105"
                  : "text-muted-foreground/50 hover:text-muted-foreground"
              }`}
              aria-label={tab.label}
            >
              <div className={`relative flex items-center justify-center h-7 w-7 transition-all ${isActive ? "text-primary" : ""}`}>
                <Icon className="h-5 w-5" strokeWidth={isActive ? 2.5 : 1.5} />
                {isActive && (
                  <div className="absolute -top-0.5 h-1 w-4 rounded-full bg-primary shadow-sm shadow-primary/30" />
                )}
              </div>
              <span className={`text-[10px] font-medium tracking-wide ${isActive ? "text-primary" : ""}`}>
                {tab.label}
              </span>
            </button>
          );
        })}
      </nav>
    </div>
  );
}