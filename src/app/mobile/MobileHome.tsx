/**
 * MobileHome — Écran Accueil connecté Supabase
 * Reçoit les données de useCommunityData via props
 */
import { Sparkles, TrendingUp, Music4, Palette, BookOpen, Film, Heart } from "lucide-react";
import type { CommunityData, CommunityDataSource, Artist, Artwork, Discussion } from "../data/community";
import { getCategoryLabel } from "../data/community";

interface Props {
  data: CommunityData;
  source: CommunityDataSource;
}

const QUICK_CATEGORIES = [
  { slug: "music" as const, icon: Music4, label: "Musique", color: "from-violet-500 to-purple-600" },
  { slug: "visual-art" as const, icon: Palette, label: "Art Visuel", color: "from-orange-500 to-red-500" },
  { slug: "manga" as const, icon: BookOpen, label: "Manga", color: "from-blue-500 to-cyan-500" },
  { slug: "film" as const, icon: Film, label: "Cinéma", color: "from-emerald-500 to-teal-600" },
];

const CATEGORY_GRADIENT: Record<string, string> = {
  music: "from-primary/30 to-accent/20",
  "visual-art": "from-orange-500/30 to-red-500/20",
  manga: "from-blue-500/30 to-cyan-500/20",
  film: "from-emerald-500/30 to-teal-600/20",
  literature: "from-rose-500/30 to-pink-600/20",
  animation: "from-cyan-500/30 to-blue-600/20",
};

function ArtworkCard({ item }: { item: Artwork }) {
  return (
    <div className="app-surface flex-shrink-0 w-40 overflow-hidden active:scale-[0.97] transition-transform duration-100 touch-manipulation">
      <div className={`h-28 bg-gradient-to-br ${CATEGORY_GRADIENT[item.category] || "from-primary/30 to-accent/20"} flex items-center justify-center relative overflow-hidden`}>
        <div className="absolute inset-0 bg-gradient-to-t from-background/90 via-card/30 to-transparent" />
        <div className="absolute -right-4 -top-4 h-14 w-14 rounded-full bg-white/10 blur-xl" />
        <Sparkles className="h-8 w-8 text-white/60" />
      </div>
      <div className="p-3">
        <h3 className="text-sm font-semibold text-foreground truncate">{item.title}</h3>
        <p className="text-[11px] text-muted-foreground truncate mt-0.5">{item.artist}</p>
        <div className="flex items-center gap-2 mt-2">
          <span className="text-[10px] font-medium text-muted-foreground/60">{item.medium}</span>
          <span className="inline-flex items-center gap-1 text-[10px] font-medium text-primary bg-primary/10 px-2 py-0.5 rounded-full">
            <Heart className="h-3 w-3 fill-primary" />
            {item.likes}
          </span>
        </div>
      </div>
    </div>
  );
}

function DiscussionRow({ item }: { item: Discussion }) {
  return (
    <div className="flex items-center gap-3 px-4 py-3 active:bg-card/50 transition-colors duration-100 touch-manipulation rounded-xl">
      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary via-secondary to-accent shadow-md shadow-primary/20">
        <span className="text-xs font-bold text-primary-foreground">{item.author.charAt(0)}</span>
      </div>
      <div className="flex-1 min-w-0">
        <h3 className="text-sm font-semibold text-foreground truncate">{item.title}</h3>
        <p className="text-[11px] text-muted-foreground truncate mt-0.5">
          {item.author} · {getCategoryLabel(item.category)}
        </p>
      </div>
      <div className="flex items-center gap-3 text-xs font-medium text-muted-foreground shrink-0">
        <span className="flex items-center gap-1">
          <Heart className="h-3.5 w-3.5" />
          {item.replies}
        </span>
        {item.trending && (
          <span className="text-[10px] font-semibold text-secondary bg-secondary/10 px-2 py-0.5 rounded-full">
            🔥
          </span>
        )}
      </div>
    </div>
  );
}

export function MobileHome({ data, source }: Props) {
  const artworks = data.artworks.slice(0, 5);
  const discussions = data.discussions.slice(0, 5);

  return (
    <div className="app-page space-y-8">
      {/* Hero Banner */}
      <div className="app-hero-surface">
        <div className="absolute -top-10 -right-10 h-28 w-28 rounded-full bg-primary/20 blur-3xl" />
        <div className="absolute -bottom-6 -left-6 h-24 w-24 rounded-full bg-secondary/20 blur-3xl" />
        <div className="absolute inset-0 opacity-30 [background-image:linear-gradient(rgba(255,255,255,0.035)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.035)_1px,transparent_1px)] [background-size:28px_28px] [mask-image:radial-gradient(circle_at_center,black,transparent_75%)]" />
        <span className="app-kicker relative mb-4">
          {source === "supabase" ? "Données Supabase" : "Bienvenue sur Artéïa"}
        </span>
        <h1 className="relative text-3xl font-bold text-foreground mb-2 tracking-tight leading-tight">
          Ta créativité,<br />ton univers
        </h1>
        <p className="relative text-sm text-muted-foreground leading-relaxed">
          {data.categories.length} univers · {data.artists.length} artistes · {data.artworks.length} œuvres
        </p>
        <div className="relative mt-5 flex flex-wrap gap-2">
          <span className="app-pill text-primary">Galerie vivante</span>
          <span className="app-pill text-secondary">Couleurs vibrantes</span>
          <span className="app-pill text-accent">Communauté créative</span>
        </div>
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="app-heading mb-4">
          Univers
        </h2>
        <div className="grid grid-cols-4 gap-3">
          {QUICK_CATEGORIES.map((cat) => {
            const categoryData = data.categories.find(c => c.slug === cat.slug);
            return (
              <button
                key={cat.slug}
                className="app-surface-soft flex flex-col items-center gap-2 p-3 active:scale-95 transition-all duration-100 touch-manipulation"
              >
                <div className={`flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br ${cat.color} shadow-md`}>
                  <cat.icon className="h-5 w-5 text-white" />
                </div>
                <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">
                  {cat.label}
                </span>
                {categoryData && (
                  <span className="text-[9px] text-muted-foreground/40">
                    {data.artworks.filter(a => a.category === cat.slug).length} œuvres
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* À la une — Top artworks */}
      {artworks.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="h-4 w-4 text-primary" />
            <h2 className="app-heading">
              À la une
            </h2>
          </div>
          <div className="flex gap-3 overflow-x-auto scrollbar-hide -mx-4 px-4 pb-2">
            {artworks.map((item, i) => (
              <ArtworkCard key={`${item.title}-${i}`} item={item} />
            ))}
          </div>
        </div>
      )}

      {/* Activité récente — Discussions */}
      {discussions.length > 0 && (
        <div>
          <h2 className="app-heading mb-3">
            Discussions récentes
          </h2>
          <div className="app-surface-soft divide-y divide-border/20 overflow-hidden">
            {discussions.map((item) => (
              <DiscussionRow key={item.title} item={item} />
            ))}
          </div>
        </div>
      )}

      {/* Empty state */}
      {artworks.length === 0 && discussions.length === 0 && (
        <div className="text-center py-12">
          <Sparkles className="h-10 w-10 text-muted-foreground/20 mx-auto mb-3" />
          <p className="text-sm text-muted-foreground">Aucune donnée pour le moment</p>
          <p className="text-xs text-muted-foreground/50 mt-1">
            {source === "supabase" ? "Ajoute du contenu via l'admin ou l'API Supabase" : "Les données mock sont vides"}
          </p>
        </div>
      )}
    </div>
  );
}
