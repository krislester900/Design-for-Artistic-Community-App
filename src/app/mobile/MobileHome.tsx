/**
 * MobileHome — Écran Accueil (Spec v2)
 * Hero banner, grille 4 univers, carrousel artworks, feed
 */
import { Sparkles, TrendingUp, Music4, Palette, BookOpen, Film, Heart } from "lucide-react";

interface QuickAction {
  icon: typeof Music4;
  label: string;
  color: string;
}

interface ArtworkItem {
  title: string;
  artist: string;
  likes: number;
  gradient: string;
}

interface FeedItem {
  avatar: string;
  title: string;
  subtitle: string;
  likes: number;
}

const QUICK_ACTIONS: QuickAction[] = [
  { icon: Music4, label: "Musique", color: "from-violet-500 to-purple-600" },
  { icon: Palette, label: "Art Visuel", color: "from-orange-500 to-red-500" },
  { icon: BookOpen, label: "Manga", color: "from-blue-500 to-cyan-500" },
  { icon: Film, label: "Cinéma", color: "from-emerald-500 to-teal-600" },
];

const ARTWORKS: ArtworkItem[] = [
  { title: "Éclat Nocturne", artist: "Maya K.", likes: 234, gradient: "from-primary/30 to-accent/20" },
  { title: "Nébuleuse Urbaine", artist: "DX-7", likes: 189, gradient: "from-violet-500/30 to-purple-600/20" },
  { title: "Kaiju Rising", artist: "T. Ito", likes: 456, gradient: "from-cyan-500/30 to-blue-600/20" },
];

const FEED: FeedItem[] = [
  { avatar: "D", title: "Nouvel album électro — Phase IV", subtitle: "DJ Katalyst · Musique", likes: 234 },
  { avatar: "U", title: "Expo street art — Berlin Underground", subtitle: "Urban Collective · Art Visuel", likes: 189 },
  { avatar: "K", title: "Chapitre 42 — Nexus War", subtitle: "K. Yamamoto · Manga", likes: 456 },
  { avatar: "L", title: "Court-métrage — Dernier Souffle", subtitle: "L. Moreau · Cinéma", likes: 127 },
  { avatar: "A", title: "Poème illustré — Les Murailles", subtitle: "A. Césaire · Littérature", likes: 89 },
];

function ArtworkCard({ item }: { item: ArtworkItem }) {
  return (
    <div className="flex-shrink-0 w-40 rounded-2xl bg-card border border-border/30 overflow-hidden shadow-card active:scale-[0.97] transition-transform duration-100 touch-manipulation">
      <div className={`h-28 bg-gradient-to-br ${item.gradient} flex items-center justify-center relative overflow-hidden`}>
        <div className="absolute inset-0 bg-gradient-to-t from-card/80 to-transparent" />
        <Sparkles className="h-8 w-8 text-primary/40" />
      </div>
      <div className="p-3">
        <h3 className="text-sm font-semibold text-foreground truncate">{item.title}</h3>
        <p className="text-[11px] text-muted-foreground truncate mt-0.5">{item.artist}</p>
        <span className="inline-flex items-center gap-1 mt-2 text-[10px] font-medium text-primary bg-primary/10 px-2 py-0.5 rounded-full">
          <Heart className="h-3 w-3 fill-primary" />
          {item.likes}
        </span>
      </div>
    </div>
  );
}

function FeedRow({ item }: { item: FeedItem }) {
  return (
    <div className="flex items-center gap-3 px-4 py-3 active:bg-card/50 transition-colors duration-100 touch-manipulation rounded-xl">
      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary to-accent shadow-md shadow-primary/10">
        <span className="text-xs font-bold text-primary-foreground">{item.avatar}</span>
      </div>
      <div className="flex-1 min-w-0">
        <h3 className="text-sm font-semibold text-foreground truncate">{item.title}</h3>
        <p className="text-[11px] text-muted-foreground truncate mt-0.5">{item.subtitle}</p>
      </div>
      <span className="flex items-center gap-1 text-xs font-medium text-muted-foreground shrink-0">
        <Heart className="h-3.5 w-3.5" />
        {item.likes}
      </span>
    </div>
  );
}

export function MobileHome() {
  return (
    <div className="px-4 py-6 space-y-8 pb-24">
      {/* Hero Banner */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-primary/10 via-background to-accent/5 border border-border/30 p-6 shadow-card">
        {/* Decorative blobs */}
        <div className="absolute -top-6 -right-6 h-20 w-20 rounded-full bg-primary/10 blur-xl" />
        <div className="absolute -bottom-4 -left-4 h-16 w-16 rounded-full bg-accent/10 blur-xl" />
        {/* Content */}
        <span className="relative inline-block rounded-full bg-primary px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.2em] text-primary-foreground mb-4">
          Bienvenue sur Artéïa
        </span>
        <h1 className="relative text-2xl font-bold text-foreground mb-2 tracking-tight">
          Ta créativité,<br />ton univers
        </h1>
        <p className="relative text-sm text-muted-foreground leading-relaxed">
          Explore, crée, partage — la communauté artistique où chaque œuvre trouve sa place.
        </p>
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-4">
          Univers
        </h2>
        <div className="grid grid-cols-4 gap-3">
          {QUICK_ACTIONS.map((action) => (
            <button
              key={action.label}
              className="flex flex-col items-center gap-2 p-3 rounded-2xl bg-card border border-border/50 active:scale-95 active:bg-surface transition-all duration-100 touch-manipulation"
            >
              <div className={`flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br ${action.color} shadow-md`}>
                <action.icon className="h-5 w-5 text-white" />
              </div>
              <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">
                {action.label}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* À la une */}
      <div>
        <div className="flex items-center gap-2 mb-4">
          <TrendingUp className="h-4 w-4 text-primary" />
          <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80">
            À la une
          </h2>
        </div>
        <div className="flex gap-3 overflow-x-auto scrollbar-hide -mx-4 px-4 pb-2">
          {ARTWORKS.map((item) => (
            <ArtworkCard key={item.title} item={item} />
          ))}
        </div>
      </div>

      {/* Feed récent */}
      <div>
        <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-3">
          Activité récente
        </h2>
        <div className="rounded-2xl bg-card/60 border border-border/30 divide-y divide-border/20 overflow-hidden">
          {FEED.map((item) => (
            <FeedRow key={item.title} item={item} />
          ))}
        </div>
      </div>
    </div>
  );
}