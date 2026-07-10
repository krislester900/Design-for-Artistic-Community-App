/**
 * MobileDrawer — Drawer latéral complexe avec navigation
 */
import { useState } from "react";
import { 
  X, Home, Compass, Search, MessageCircle, Inbox, User, Bell, Settings, 
  Heart, Bookmark, Star, TrendingUp, Music4, Palette, BookOpen, 
  Film, Pen, Clapperboard, Shield, HelpCircle, Globe, Moon, Sun,
  ChevronRight, LogOut, Camera, Edit3, Share2, Plus, Eye, Users,
  Trophy, Flame, Clock, Grid3X3, List, SlidersHorizontal, ChevronDown,
  Sparkles
} from "lucide-react";

interface DrawerProps {
  isOpen: boolean;
  onClose: () => void;
  activeTab: string;
  onNavigate: (tab: string) => void;
}

interface MenuItem {
  icon: typeof Home;
  label: string;
  color: string;
  badge?: number;
  action?: () => void;
}

const MENU_ITEMS: MenuItem[] = [
  { icon: Home, label: "Accueil", color: "text-primary" },
  { icon: Inbox, label: "Messages", color: "text-blue-400" },
  { icon: Compass, label: "Explorer", color: "text-cyan-400" },
  { icon: Search, label: "Rechercher", color: "text-green-400" },
  { icon: MessageCircle, label: "Communauté", color: "text-violet-400", badge: 3 },
  { icon: User, label: "Profil", color: "text-amber-400" },
  { icon: Bell, label: "Notifications", color: "text-rose-400", badge: 5 },
  { icon: Heart, label: "Favoris", color: "text-red-400", badge: 24 },
  { icon: Bookmark, label: "Enregistrés", color: "text-amber-400", badge: 8 },
  { icon: Star, label: "Tendances", color: "text-yellow-400" },
  { icon: TrendingUp, label: "Statistiques", color: "text-emerald-400" },
];

const UNIVERSES = [
  { icon: Music4, label: "Musique", color: "text-violet-400", gradient: "from-violet-500 to-purple-500" },
  { icon: Palette, label: "Art Visuel", color: "text-orange-400", gradient: "from-orange-500 to-red-500" },
  { icon: BookOpen, label: "Manga", color: "text-blue-400", gradient: "from-blue-500 to-cyan-500" },
  { icon: Film, label: "Films", color: "text-emerald-400", gradient: "from-emerald-500 to-teal-500" },
  { icon: Pen, label: "Littérature", color: "text-rose-400", gradient: "from-rose-500 to-pink-500" },
  { icon: Clapperboard, label: "Animation", color: "text-cyan-400", gradient: "from-cyan-500 to-blue-500" },
];

const SETTINGS_ITEMS = [
  { icon: Moon, label: "Mode sombre", color: "text-primary" },
  { icon: Bell, label: "Notifications", color: "text-cyan-400" },
  { icon: Globe, label: "Langue", color: "text-green-400" },
  { icon: Shield, label: "Confidentialité", color: "text-primary" },
  { icon: HelpCircle, label: "Aide & Support", color: "text-amber-400" },
];

export function MobileDrawer({ isOpen, onClose, activeTab, onNavigate }: DrawerProps) {
  const [activeSection, setActiveSection] = useState<"menu" | "universes" | "settings">("menu");

  if (!isOpen) return null;

  return (
    <>
      {/* Overlay */}
      <div 
        className="fixed inset-0 bg-black/50 backdrop-blur-sm z-40 transition-opacity duration-300"
        onClick={onClose}
      />
      
      {/* Drawer */}
      <div className="fixed left-0 top-0 bottom-0 w-80 bg-background border-r border-border/30 z-50 flex flex-col overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border/20">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-accent shadow-lg shadow-primary/20">
              <Sparkles className="h-5 w-5 text-primary-foreground" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-foreground" style={{ fontFamily: "'Alien Block', cursive" }}>Artéïa</h2>
              <p className="text-[10px] text-muted-foreground">Communauté artistique</p>
            </div>
          </div>
          <button onClick={onClose} className="h-8 w-8 rounded-lg bg-card/60 border border-border/30 flex items-center justify-center active:scale-90 transition-all">
            <X className="h-4 w-4 text-muted-foreground" />
          </button>
        </div>

        {/* Section Tabs */}
        <div className="flex gap-1 px-4 py-2 border-b border-border/20">
          {[
            { id: "menu" as const, label: "Menu" },
            { id: "universes" as const, label: "Univers" },
            { id: "settings" as const, label: "Paramètres" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveSection(tab.id)}
              className={`flex-1 py-2 rounded-lg text-xs font-medium transition-all ${
                activeSection === tab.id
                  ? "bg-primary/15 text-primary"
                  : "text-muted-foreground"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto">
          {activeSection === "menu" && (
            <div className="py-2">
              {MENU_ITEMS.map((item) => (
                <button
                  key={item.label}
                  onClick={() => { onNavigate(item.label.toLowerCase()); onClose(); }}
                  className={`flex items-center gap-3 w-full px-5 py-3 active:bg-card/60 transition-colors duration-100 touch-manipulation ${
                    activeTab === item.label.toLowerCase() ? "bg-primary/10" : ""
                  }`}
                >
                  <item.icon className={`h-5 w-5 shrink-0 ${item.color}`} />
                  <span className="flex-1 text-left text-sm font-medium text-foreground">{item.label}</span>
                  {item.badge && (
                    <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary/15 text-[10px] font-bold text-primary px-1.5">
                      {item.badge}
                    </span>
                  )}
                  <ChevronRight className="h-4 w-4 text-muted-foreground/30" />
                </button>
              ))}
            </div>
          )}

          {activeSection === "universes" && (
            <div className="py-2">
              <div className="px-5 py-2">
                <p className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground">Univers</p>
              </div>
              {UNIVERSES.map((universe) => (
                <button
                  key={universe.label}
                  onClick={() => { onNavigate("explore"); onClose(); }}
                  className="flex items-center gap-3 w-full px-5 py-3 active:bg-card/60 transition-colors duration-100 touch-manipulation"
                >
                  <div className={`h-8 w-8 rounded-lg bg-gradient-to-br ${universe.gradient} flex items-center justify-center`}>
                    <universe.icon className="h-4 w-4 text-white" />
                  </div>
                  <span className="flex-1 text-left text-sm font-medium text-foreground">{universe.label}</span>
                  <ChevronRight className="h-4 w-4 text-muted-foreground/30" />
                </button>
              ))}
            </div>
          )}

          {activeSection === "settings" && (
            <div className="py-2">
              <div className="px-5 py-2">
                <p className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground">Paramètres</p>
              </div>
              {SETTINGS_ITEMS.map((item) => (
                <button
                  key={item.label}
                  className="flex items-center gap-3 w-full px-5 py-3 active:bg-card/60 transition-colors duration-100 touch-manipulation"
                >
                  <item.icon className={`h-5 w-5 shrink-0 ${item.color}`} />
                  <span className="flex-1 text-left text-sm font-medium text-foreground">{item.label}</span>
                  <ChevronRight className="h-4 w-4 text-muted-foreground/30" />
                </button>
              ))}
              
              <div className="mx-5 my-3 border-t border-border/20" />
              
              <button className="flex items-center gap-3 w-full px-5 py-3 active:bg-card/60 transition-colors duration-100 touch-manipulation">
                <LogOut className="h-5 w-5 shrink-0 text-red-400" />
                <span className="flex-1 text-left text-sm font-medium text-red-400">Déconnexion</span>
              </button>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-border/20">
          <p className="text-[10px] text-muted-foreground/50 uppercase tracking-[0.2em] text-center">Artéïa v1.0.0</p>
        </div>
      </div>
    </>
  );
}