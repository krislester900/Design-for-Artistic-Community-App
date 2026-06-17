/**
 * MobileExplore — Écran Explorer connecté Supabase
 */
import { useState } from "react";
import { Search, Music4, Palette, BookOpen, Film, Pen, Clapperboard, Sparkles } from "lucide-react";
import type { CommunityData, CategorySlug } from "../data/community";
import { getCategoryLabel } from "../data/community";
import { MobileUniverse } from "./MobileUniverse";

interface Props {
  data: CommunityData;
}

const CATEGORY_ICONS: Record<string, typeof Music4> = {
  music: Music4,
  "visual-art": Palette,
  manga: BookOpen,
  film: Film,
  literature: Pen,
  animation: Clapperboard,
};

const CATEGORY_GRADIENTS: Record<string, string> = {
  music: "from-violet-500/20 to-purple-600/15",
  "visual-art": "from-orange-500/20 to-red-500/15",
  manga: "from-blue-500/20 to-cyan-500/15",
  film: "from-emerald-500/20 to-teal-600/15",
  literature: "from-rose-500/20 to-pink-600/15",
  animation: "from-cyan-500/20 to-blue-600/15",
};

const CATEGORY_COLORS: Record<string, string> = {
  music: "bg-violet-500/20 text-violet-400",
  "visual-art": "bg-orange-500/20 text-orange-400",
  manga: "bg-blue-500/20 text-blue-400",
  film: "bg-emerald-500/20 text-emerald-400",
  literature: "bg-rose-500/20 text-rose-400",
  animation: "bg-cyan-500/20 text-cyan-400",
};

const ARTIST_GRADIENTS: Record<string, string> = {
  music: "from-violet-500/20 to-purple-600/10",
  "visual-art": "from-orange-500/20 to-red-500/10",
  manga: "from-blue-500/20 to-cyan-500/10",
  film: "from-emerald-500/20 to-teal-600/10",
  literature: "from-rose-500/20 to-pink-600/10",
  animation: "from-cyan-500/20 to-blue-600/10",
};

const FILTERS = ["Tous", "Tendance", "Nouveau", "Populaire"];

export function MobileExplore({ data }: Props) {
  const [activeFilter, setActiveFilter] = useState("Tous");
  const [searchQuery, setSearchQuery] = useState("");
  const [activeUniverse, setActiveUniverse] = useState<string | null>(null);

  const filteredArtists = data.artists.filter((a) => {
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return a.name.toLowerCase().includes(q) || a.role.toLowerCase().includes(q);
    }
    return true;
  });

  if (activeUniverse) {
    return <MobileUniverse slug={activeUniverse} onBack={() => setActiveUniverse(null)} />;
  }

  return (
    <div className="px-4 py-6 space-y-8 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-foreground mb-1">Explorer</h1>
        <p className="text-xs text-muted-foreground">{data.categories.length} univers · {data.artists.length} artistes · {data.artworks.length} œuvres</p>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground/40" />
        <input
          className="w-full h-11 pl-10 pr-4 rounded-xl border border-border/50 bg-card/60 text-sm text-foreground outline-none placeholder:text-muted-foreground/30 focus:border-primary/50 focus:ring-2 focus:ring-primary/5 transition-all"
          placeholder="Rechercher un artiste, une œuvre..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {/* Categories Grid */}
      <div>
        <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-4">
          Catégories
        </h2>
        <div className="grid grid-cols-3 gap-3">
          {data.categories.map((cat) => {
            const Icon = CATEGORY_ICONS[cat.slug] || Palette;
            const artworkCount = data.artworks.filter(a => a.category === cat.slug).length;
            return (
              <button
                key={cat.slug}
                onClick={() => setActiveUniverse(cat.slug)}
                className="flex flex-col items-center justify-center gap-2 p-4 rounded-2xl bg-card border border-border/30 active:scale-95 active:border-primary/30 transition-all duration-100 touch-manipulation"
              >
                <div className={`flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br ${CATEGORY_GRADIENTS[cat.slug] || "from-primary/20 to-accent/15"} ${CATEGORY_COLORS[cat.slug]?.split(" ")[1] || "text-primary"}`}>
                  <Icon className="h-6 w-6" />
                </div>
                <h3 className="text-sm font-semibold text-foreground">{cat.shortLabel || cat.title}</h3>
                <p className="text-[11px] text-muted-foreground">{artworkCount} œuvres</p>
              </button>
            );
          })}
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
          Artistes ({filteredArtists.length})
        </h2>
        {filteredArtists.length > 0 ? (
          <div className="grid grid-cols-2 gap-3">
            {filteredArtists.map((artist) => (
              <div
                key={artist.name}
                className="rounded-2xl bg-card border border-border/30 overflow-hidden active:scale-[0.97] transition-transform duration-100 touch-manipulation shadow-card"
              >
                <div className={`h-36 bg-gradient-to-br ${ARTIST_GRADIENTS[artist.category] || "from-primary/20 to-accent/10"} flex items-center justify-center relative`}>
                  <div className="absolute inset-0 bg-gradient-to-t from-card/90 to-transparent" />
                  <Palette className="h-10 w-10 text-foreground/5" />
                </div>
                <div className="p-3">
                  <h3 className="text-sm font-semibold text-foreground truncate">{artist.name}</h3>
                  <p className="text-[11px] text-muted-foreground truncate mt-0.5">{artist.role}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className={`inline-block text-[10px] font-medium px-2 py-0.5 rounded-full ${CATEGORY_COLORS[artist.category] || "bg-primary/10 text-primary"}`}>
                      {getCategoryLabel(artist.category)}
                    </span>
                    <span className="text-[10px] text-muted-foreground/50">{artist.likes} ❤️</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <Sparkles className="h-10 w-10 text-muted-foreground/20 mx-auto mb-3" />
            <p className="text-sm text-muted-foreground">Aucun artiste trouvé</p>
            <p className="text-xs text-muted-foreground/50 mt-1">Essaie une autre recherche</p>
          </div>
        )}
      </div>
    </div>
  );
}
