/** MobileExplore — Explore les univers artistiques */
import { Music4, Palette, BookOpen, Film, Pen, Clapperboard } from "lucide-react";

const CATEGORIES = [
  { icon: Music4, name: "Musique", slug: "music", color: "bg-violet-500/20 text-violet-400", count: 42 },
  { icon: Palette, name: "Art Visuel", slug: "visual-art", color: "bg-orange-500/20 text-orange-400", count: 38 },
  { icon: BookOpen, name: "Manga", slug: "manga", color: "bg-blue-500/20 text-blue-400", count: 56 },
  { icon: Film, name: "Films", slug: "film", color: "bg-emerald-500/20 text-emerald-400", count: 31 },
  { icon: Pen, name: "Littérature", slug: "literature", color: "bg-rose-500/20 text-rose-400", count: 27 },
  { icon: Clapperboard, name: "Animation", slug: "animation", color: "bg-cyan-500/20 text-cyan-400", count: 19 },
];

export function MobileExplore() {
  return (
    <div className="px-4 py-6 space-y-6 pb-20">
      <div>
        <h1 className="text-2xl font-bold text-foreground mb-1">Explorer</h1>
        <p className="text-xs text-muted-foreground">Les univers créatifs d'Artéïa</p>
      </div>

      {/* Categories grid */}
      <div className="grid grid-cols-2 gap-3">
        {CATEGORIES.map((cat) => (
          <button
            key={cat.slug}
            className="flex flex-col items-start gap-3 p-4 rounded-2xl bg-card/60 border border-border/50 active:scale-95 transition-all touch-manipulation hover:bg-card"
          >
            <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${cat.color}`}>
              <cat.icon className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-sm font-semibold text-foreground">{cat.name}</h3>
              <p className="text-xs text-muted-foreground">{cat.count} œuvres</p>
            </div>
          </button>
        ))}
      </div>

      {/* Featured artists section */}
      <div>
        <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-3">
          Artistes à la une
        </h2>
        <div className="flex gap-3 overflow-x-auto scrollbar-hide pb-2">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="flex-shrink-0 w-40 rounded-2xl bg-card/60 border border-border/50 overflow-hidden"
            >
              <div className="h-24 bg-gradient-to-br from-primary/30 to-accent/20 flex items-center justify-center">
                <Palette className="h-8 w-8 text-primary/50" />
              </div>
              <div className="p-3">
                <h3 className="text-sm font-semibold text-foreground">Artiste {i}</h3>
                <p className="text-xs text-muted-foreground">Art visuel</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}