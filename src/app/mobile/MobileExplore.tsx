/**
 * MobileExplore — Écran Explorer (Spec v2)
 * Barre de recherche, grille catégories, filtres chips, grille artistes
 */
import { useState } from "react";
import { Search, Music4, Palette, BookOpen, Film, Pen, Clapperboard } from "lucide-react";

interface Category {
  icon: typeof Music4;
  name: string;
  slug: string;
  gradient: string;
  count: number;
}

interface ArtistCard {
  name: string;
  role: string;
  category: string;
  gradient: string;
}

const CATEGORIES: Category[] = [
  { icon: Music4, name: "Musique", slug: "music", gradient: "from-violet-500/20 to-purple-600/15 text-violet-400", count: 42 },
  { icon: Palette, name: "Art Visuel", slug: "visual-art", gradient: "from-orange-500/20 to-red-500/15 text-orange-400", count: 38 },
  { icon: BookOpen, name: "Manga", slug: "manga", gradient: "from-blue-500/20 to-cyan-500/15 text-blue-400", count: 56 },
  { icon: Film, name: "Films", slug: "film", gradient: "from-emerald-500/20 to-teal-600/15 text-emerald-400", count: 31 },
  { icon: Pen, name: "Littérature", slug: "literature", gradient: "from-rose-500/20 to-pink-600/15 text-rose-400", count: 27 },
  { icon: Clapperboard, name: "Animation", slug: "animation", gradient: "from-cyan-500/20 to-blue-600/15 text-cyan-400", count: 19 },
];

const FILTERS = ["Tous", "Tendance", "Nouveau", "Populaire"];

const ARTISTS: ArtistCard[] = [
  { name: "Maya K.", role: "Artiste visuelle", category: "art-visuel", gradient: "from-orange-500/20 to-red-500/10" },
  { name: "DJ Katalyst", role: "Producteur", category: "music", gradient: "from-violet-500/20 to-purple-600/10" },
  { name: "T. Ito", role: "Mangaka", category: "manga", gradient: "from-blue-500/20 to-cyan-500/10" },
  { name: "L. Moreau", role: "Réalisateur", category: "film", gradient: "from-emerald-500/20 to-teal-600/10" },
];

const CATEGORY_COLORS: Record<string, string> = {
  music: "bg-violet-500/20 text-violet-400",
  "visual-art": "bg-orange-500/20 text-orange-400",
  manga: "bg-blue-500/20 text-blue-400",
  film: "bg-emerald-500/20 text-emerald-400",
  literature: "bg-rose-500/20 text-rose-400",
  animation: "bg-cyan-500/20 text-cyan-400",
};

export function MobileExplore() {
  const [activeFilter, setActiveFilter] = useState("Tous");

  return (
    <div className="px-4 py-6 space-y-8 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-foreground mb-1">Explorer</h1>
        <p className="text-xs text-muted-foreground">Les univers créatifs d'Artéïa</p>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground/40" />
        <input
          className="w-full h-11 pl-10 pr-4 rounded-xl border border-border/50 bg-card/60 text-sm text-foreground outline-none placeholder:text-muted-foreground/30 focus:border-primary/50 focus:ring-2 focus:ring-primary/5 transition-all"
          placeholder="Rechercher un artiste, une œuvre..."
        />
      </div>

      {/* Categories Grid */}
      <div>
        <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-4">
          Catégories
        </h2>
        <div className="grid grid-cols-3 gap-3">
          {CATEGORIES.map((cat) => (
            <button
              key={cat.slug}
              className={`flex flex-col items-center justify-center gap-2 p-4 rounded-2xl bg-card border border-border/30 active:scale-95 active:border-primary/30 transition-all duration-100 touch-manipulation`}
            >
              <div className={`flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br ${cat.gradient}`}>
                <cat.icon className="h-6 w-6" />
              </div>
              <h3 className="text-sm font-semibold text-foreground">{cat.name}</h3>
              <p className="text-[11px] text-muted-foreground">{cat.count} œuvres</p>
            </button>
          ))}
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-2 overflow-x-auto scrollbar-hide">
        {FILTERS.map((filter) => (
          <button
            key={filter}
            onClick={() => setActiveFilter(filter)}
            className={`shrink-0 px-4 py-1.5 rounded-full text-xs font-medium transition-all duration-150 active:scale-95 touch-manipulation ${
              activeFilter === filter
                ? "bg-primary/15 border border-primary/30 text-primary"
                : "bg-card border border-border/40 text-muted-foreground hover:border-border/60"
            }`}
          >
            {filter}
          </button>
        ))}
      </div>

      {/* Artists Grid */}
      <div>
        <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-4">
          Artistes à la une
        </h2>
        <div className="grid grid-cols-2 gap-3">
          {ARTISTS.map((artist) => (
            <div
              key={artist.name}
              className="rounded-2xl bg-card border border-border/30 overflow-hidden active:scale-[0.97] transition-transform duration-100 touch-manipulation shadow-card"
            >
              <div className={`h-36 bg-gradient-to-br ${artist.gradient} flex items-center justify-center relative`}>
                <div className="absolute inset-0 bg-gradient-to-t from-card/90 to-transparent" />
                <Palette className="h-10 w-10 text-foreground/10" />
              </div>
              <div className="p-3">
                <h3 className="text-sm font-semibold text-foreground truncate">{artist.name}</h3>
                <p className="text-[11px] text-muted-foreground truncate mt-0.5">{artist.role}</p>
                <span className={`inline-block mt-2 text-[10px] font-medium px-2 py-0.5 rounded-full ${CATEGORY_COLORS[artist.category] || 'bg-primary/10 text-primary'}`}>
                  {artist.category === "visual-art" ? "Art Visuel" : artist.category.charAt(0).toUpperCase() + artist.category.slice(1)}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}