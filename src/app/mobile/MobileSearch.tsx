/**
 * MobileSearch — Recherche avancée avec filtres
 */
import { useState, useMemo } from "react";
import { Search, X, Filter, Heart, Eye, Clock, TrendingUp, Music4, Palette, BookOpen, Film, Pen, Clapperboard, SlidersHorizontal, ChevronDown } from "lucide-react";

interface SearchResult {
  id: string;
  title: string;
  artist: string;
  category: string;
  type: "artwork" | "artist" | "post";
  likes: number;
  views: number;
  emoji: string;
  gradient: string;
  tags: string[];
}

const MOCK_DATA: SearchResult[] = [
  { id: "1", title: "Portrait Neon", artist: "ArtDiva", category: "Art Visuel", type: "artwork", likes: 234, views: 1200, emoji: "🎨", gradient: "from-orange-500 to-red-500", tags: ["portrait", "neon", "digital"] },
  { id: "2", title: "Beat Afro-Trap", artist: "DJ Artéïa", category: "Musique", type: "artwork", likes: 342, views: 890, emoji: "🎵", gradient: "from-violet-500 to-purple-500", tags: ["beat", "afro", "trap"] },
  { id: "3", title: "Naruto Fan Art", artist: "MangaKing", category: "Manga", type: "artwork", likes: 567, views: 2100, emoji: "📚", gradient: "from-blue-500 to-cyan-500", tags: ["naruto", "fanart", "anime"] },
  { id: "4", title: "Court-Métrage Paris", artist: "FilmMaker", category: "Films", type: "artwork", likes: 287, views: 1560, emoji: "🎬", gradient: "from-emerald-500 to-teal-500", tags: ["paris", "court-métrage", "cinéma"] },
  { id: "5", title: "Les Mots Perdus", artist: "PoèteNuit", category: "Littérature", type: "artwork", likes: 432, views: 780, emoji: "✍️", gradient: "from-rose-500 to-pink-500", tags: ["poésie", "nuit", "mots"] },
  { id: "6", title: "Loop Satisfaisante", artist: "MotionPro", category: "Animation", type: "artwork", likes: 567, views: 3400, emoji: "🎞️", gradient: "from-cyan-500 to-blue-500", tags: ["loop", "motion", "satisfaisant"] },
  { id: "7", title: "ArtDiva", artist: "Artiste Visuel", category: "Art Visuel", type: "artist", likes: 1200, views: 5600, emoji: "🎨", gradient: "from-orange-500 to-red-500", tags: ["peinture", "digital", "street"] },
  { id: "8", title: "DJ Artéïa", artist: "Producteur Musical", category: "Musique", type: "artist", likes: 890, views: 3200, emoji: "🎵", gradient: "from-violet-500 to-purple-500", tags: ["beat", "production", "studio"] },
  { id: "9", title: "Neon Dreams", artist: "PixelMaster", category: "Art Visuel", type: "artwork", likes: 321, views: 1800, emoji: "✨", gradient: "from-purple-500 to-pink-500", tags: ["neon", "rêve", "pixel"] },
  { id: "10", title: "Freestyle Paris", artist: "MC Nova", category: "Musique", type: "artwork", likes: 218, views: 670, emoji: "🎤", gradient: "from-red-500 to-orange-500", tags: ["freestyle", "paris", "rap"] },
];

const CATEGORIES = ["Toutes", "Art Visuel", "Musique", "Manga", "Films", "Littérature", "Animation"];
const SORT_OPTIONS = ["Populaire", "Récents", "Likes", "Vues"];
const TYPE_FILTERS = ["Tout", "Œuvres", "Artistes", "Posts"];

export function MobileSearch() {
  const [query, setQuery] = useState("");
  const [activeCategory, setActiveCategory] = useState("Toutes");
  const [activeSort, setActiveSort] = useState("Populaire");
  const [activeType, setActiveType] = useState("Tout");
  const [showFilters, setShowFilters] = useState(false);
  const [likedItems, setLikedItems] = useState<Set<string>>(new Set());

  const results = useMemo(() => {
    let filtered = MOCK_DATA;

    if (query.trim()) {
      const q = query.toLowerCase();
      filtered = filtered.filter(item =>
        item.title.toLowerCase().includes(q) ||
        item.artist.toLowerCase().includes(q) ||
        item.tags.some(t => t.includes(q))
      );
    }

    if (activeCategory !== "Toutes") {
      filtered = filtered.filter(item => item.category === activeCategory);
    }

    if (activeType !== "Tout") {
      if (activeType === "Œuvres") filtered = filtered.filter(item => item.type === "artwork");
      if (activeType === "Artistes") filtered = filtered.filter(item => item.type === "artist");
      if (activeType === "Posts") filtered = filtered.filter(item => item.type === "post");
    }

    switch (activeSort) {
      case "Récents": break;
      case "Likes": filtered.sort((a, b) => b.likes - a.likes); break;
      case "Vues": filtered.sort((a, b) => b.views - a.views); break;
      default: filtered.sort((a, b) => b.likes - a.likes);
    }

    return filtered;
  }, [query, activeCategory, activeSort, activeType]);

  const toggleLike = (id: string) => {
    setLikedItems(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  return (
    <div className="px-4 py-6 space-y-5 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-foreground" style={{ fontFamily: "'Outfit', sans-serif" }}>Rechercher</h1>
        <p className="text-xs text-muted-foreground mt-0.5">{results.length} résultats</p>
      </div>

      {/* Search Bar */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground/40" />
        <input
          className="w-full h-11 pl-10 pr-10 rounded-xl border border-border/50 bg-card/60 text-sm text-foreground outline-none placeholder:text-muted-foreground/30 focus:border-primary/50 focus:ring-2 focus:ring-primary/5 transition-all"
          placeholder="Rechercher œuvres, artistes, tags..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        {query && (
          <button onClick={() => setQuery("")} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/40">
            <X className="h-4 w-4" />
          </button>
        )}
      </div>

      {/* Quick Filters */}
      <div className="flex gap-2 overflow-x-auto scrollbar-hide">
        {CATEGORIES.map((cat) => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`shrink-0 px-4 py-1.5 rounded-full text-xs font-medium transition-all duration-150 active:scale-95 touch-manipulation ${
              activeCategory === cat
                ? "bg-primary/15 border border-primary/30 text-primary"
                : "bg-card border border-border/40 text-muted-foreground"
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Advanced Filters Toggle */}
      <button
        onClick={() => setShowFilters(!showFilters)}
        className="flex items-center gap-2 text-xs text-muted-foreground"
      >
        <SlidersHorizontal className="h-3.5 w-3.5" />
        Filtres avancés
        <ChevronDown className={`h-3.5 w-3.5 transition-transform ${showFilters ? "rotate-180" : ""}`} />
      </button>

      {/* Advanced Filters */}
      {showFilters && (
        <div className="space-y-3 p-3 rounded-2xl bg-card/60 border border-border/30">
          <div>
            <p className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground mb-2">Type</p>
            <div className="flex gap-2">
              {TYPE_FILTERS.map((type) => (
                <button
                  key={type}
                  onClick={() => setActiveType(type)}
                  className={`px-3 py-1 rounded-lg text-[11px] font-medium transition-all ${
                    activeType === type
                      ? "bg-primary/15 text-primary"
                      : "bg-muted/50 text-muted-foreground"
                  }`}
                >
                  {type}
                </button>
              ))}
            </div>
          </div>
          <div>
            <p className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground mb-2">Trier par</p>
            <div className="flex gap-2">
              {SORT_OPTIONS.map((sort) => (
                <button
                  key={sort}
                  onClick={() => setActiveSort(sort)}
                  className={`px-3 py-1 rounded-lg text-[11px] font-medium transition-all ${
                    activeSort === sort
                      ? "bg-primary/15 text-primary"
                      : "bg-muted/50 text-muted-foreground"
                  }`}
                >
                  {sort}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Results */}
      <div className="space-y-2">
        {results.map((item) => (
          <div
            key={item.id}
            className="flex items-center gap-3 p-3 rounded-2xl bg-card border border-border/30 active:scale-[0.98] transition-all duration-100 touch-manipulation"
          >
            <div className={`h-12 w-12 rounded-xl bg-gradient-to-br ${item.gradient} flex items-center justify-center shrink-0`}>
              <span className="text-xl">{item.emoji}</span>
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="text-sm font-semibold text-foreground truncate">{item.title}</h4>
              <p className="text-[11px] text-muted-foreground">{item.artist} · {item.category}</p>
              <div className="flex items-center gap-3 mt-1">
                <div className="flex items-center gap-1">
                  <Heart className="h-3 w-3 text-red-400" />
                  <span className="text-[10px] text-muted-foreground">{item.likes}</span>
                </div>
                <div className="flex items-center gap-1">
                  <Eye className="h-3 w-3 text-muted-foreground/50" />
                  <span className="text-[10px] text-muted-foreground/50">{item.views}</span>
                </div>
              </div>
            </div>
            <button
              onClick={() => toggleLike(item.id)}
              className={`shrink-0 h-9 w-9 rounded-xl flex items-center justify-center transition-all duration-200 active:scale-95 ${
                likedItems.has(item.id)
                  ? "bg-red-500/15 text-red-500"
                  : "bg-muted/50 text-muted-foreground"
              }`}
            >
              <Heart className={`h-4 w-4 ${likedItems.has(item.id) ? "fill-red-500" : ""}`} />
            </button>
          </div>
        ))}
      </div>

      {results.length === 0 && (
        <div className="text-center py-12">
          <Search className="h-10 w-10 text-muted-foreground/20 mx-auto mb-3" />
          <p className="text-sm text-muted-foreground">Aucun résultat</p>
          <p className="text-xs text-muted-foreground/50 mt-1">Essaie une autre recherche</p>
        </div>
      )}
    </div>
  );
}