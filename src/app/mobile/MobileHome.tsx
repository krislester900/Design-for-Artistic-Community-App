import { useEffect, useState } from "react";
import { useCommunityDataQuery } from "../hooks/useCommunityDataQuery";
import { useAppStore } from "../store/useAppStore";
import { getCategoryLabel, isCategoryMatch } from "../data/community";
import { ImageWithFallback } from "../components/ImageWithFallback";
import { Palette, Heart, MessageCircle, Users } from "lucide-react";
import { WelcomeBird } from "./WelcomeBird";

export function MobileHome() {
  const [isDataLoading, setIsDataLoading] = useState(true);
  const { data, isLoading } = useCommunityDataQuery();
  const selectedCategory = useAppStore((state) => state.selectedCategory);
  const setSelectedCategory = useAppStore((state) => state.setSelectedCategory);

  useEffect(() => {
    const timer = setTimeout(() => setIsDataLoading(false), 800);
    return () => clearTimeout(timer);
  }, []);

  if (isLoading || isDataLoading) {
    return (
      <div className="mobile-home relative w-full h-full flex items-center justify-center">
        <WelcomeBird />
        <div className="text-sm text-muted-foreground animate-pulse mt-20">Chargement...</div>
      </div>
    );
  }

  const filteredArtists = data.artists.filter((a) => isCategoryMatch(selectedCategory, a.category));
  const filteredArtworks = data.artworks.filter((a) => isCategoryMatch(selectedCategory, a.category));
  const filteredDiscussions = data.discussions.filter((d) => isCategoryMatch(selectedCategory, d.category));

  return (
    <div className="mobile-home relative w-full h-full overflow-y-auto pb-24">
      <WelcomeBird />

      <div className="p-4 space-y-6">
        {/* Header */}
        <div className="app-hero-surface">
          <div className="flex items-center gap-3 mb-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-accent">
              <Palette className="h-5 w-5 text-primary-foreground" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-foreground" style={{ fontFamily: "'Alien Block', cursive" }}>
                Artéïa
              </h1>
              <p className="text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
                {getCategoryLabel(selectedCategory)}
              </p>
            </div>
          </div>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Une communauté vibrante pour les artistes et passionnés de création.
          </p>
        </div>

        {/* Category filter */}
        <div className="flex gap-2 overflow-x-auto pb-2 -mx-1 px-1">
          {(["all", "music", "visual-art", "manga", "film", "literature", "animation"] as const).map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`shrink-0 rounded-full px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.1em] transition-all ${
                selectedCategory === cat
                  ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
                  : "border border-border bg-card/50 text-muted-foreground hover:text-foreground"
              }`}
            >
              {getCategoryLabel(cat)}
            </button>
          ))}
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 gap-3">
          {data.communityStats.slice(0, 4).map((stat) => (
            <div key={stat.label} className="app-surface-soft p-3 text-center">
              <p className="text-lg font-bold text-primary">{stat.number}</p>
              <p className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground">{stat.label}</p>
            </div>
          ))}
        </div>

        {/* Artists */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h3 className="app-heading">Artistes</h3>
            <Users className="h-4 w-4 text-muted-foreground" />
          </div>
          <div className="space-y-2">
            {filteredArtists.slice(0, 4).map((artist) => (
              <div key={artist.name} className="app-surface-soft flex items-center gap-3 p-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary/20 to-primary/5 text-xs font-bold text-primary">
                  {artist.name.charAt(0)}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-foreground truncate">{artist.name}</p>
                  <p className="text-[11px] text-muted-foreground">{artist.role}</p>
                </div>
                <div className="flex items-center gap-1 text-[11px] text-muted-foreground">
                  <Heart className="h-3 w-3" />
                  {artist.likes}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Artworks */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h3 className="app-heading">Œuvres</h3>
            <Palette className="h-4 w-4 text-muted-foreground" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            {filteredArtworks.slice(0, 4).map((artwork) => (
              <div key={artwork.title} className="app-surface-soft overflow-hidden">
                <div className="aspect-square bg-muted/30 relative">
                  <ImageWithFallback
                    src={artwork.image || "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400&q=80"}
                    alt={artwork.title}
                    className="h-full w-full object-cover"
                  />
                </div>
                <div className="p-2.5">
                  <p className="text-xs font-semibold text-foreground truncate">{artwork.title}</p>
                  <p className="text-[10px] text-muted-foreground">{artwork.artist}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Discussions */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h3 className="app-heading">Discussions</h3>
            <MessageCircle className="h-4 w-4 text-muted-foreground" />
          </div>
          <div className="space-y-2">
            {filteredDiscussions.slice(0, 3).map((discussion) => (
              <div key={discussion.title} className="app-surface-soft p-3">
                <p className="text-xs font-medium text-foreground line-clamp-2">{discussion.title}</p>
                <div className="mt-1 flex items-center justify-between">
                  <p className="text-[10px] text-muted-foreground">{discussion.author}</p>
                  <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
                    <MessageCircle className="h-3 w-3" />
                    {discussion.replies}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Events */}
        <div>
          <h3 className="app-heading mb-3">Événements</h3>
          <div className="space-y-2">
            {data.events.slice(0, 3).map((event) => (
              <div key={event.title} className="app-surface-soft p-3 flex items-center justify-between">
                <p className="text-xs font-medium text-foreground">{event.title}</p>
                <p className="text-[10px] text-primary">{event.date}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
