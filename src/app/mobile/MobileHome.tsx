/**
 * MobileHome — Page d'accueil optimisée mobile
 */
import { Sparkles, TrendingUp, Music4, BookOpen, Film, Palette } from "lucide-react";

const QUICK_ACTIONS = [
  { icon: Music4, label: "Musique", color: "from-violet-500 to-purple-600" },
  { icon: Palette, label: "Art Visuel", color: "from-orange-500 to-red-500" },
  { icon: BookOpen, label: "Manga", color: "from-blue-500 to-cyan-500" },
  { icon: Film, label: "Films", color: "from-emerald-500 to-teal-600" },
];

const TRENDING = [
  { title: "Nouvel album électro", author: "DJ Katalyst", likes: 234 },
  { title: "Expo street art Berlin", author: "Urban Collective", likes: 189 },
  { title: "Chapitre 42 - Nexus War", author: "K. Yamamoto", likes: 456 },
];

export function MobileHome() {
  return (
    <div className="px-4 py-6 space-y-6 pb-20">
      {/* Hero card */}
      <div className="rounded-3xl bg-gradient-to-br from-primary/20 via-background to-accent/10 p-6 border border-primary/10 shadow-lg">
        <div className="flex items-center gap-2 mb-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/20">
            <Sparkles className="h-4 w-4 text-primary" />
          </div>
          <span className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Bienvenue sur Artéïa
          </span>
        </div>
        <h1 className="text-2xl font-bold text-foreground mb-2">
          Explore, crée, partage
        </h1>
        <p className="text-sm text-muted-foreground leading-relaxed">
          La communauté artistique où ta créativité prend vie.
        </p>
      </div>

      {/* Quick actions */}
      <div>
        <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-3">
          Univers
        </h2>
        <div className="grid grid-cols-4 gap-2">
          {QUICK_ACTIONS.map((action) => (
            <button
              key={action.label}
              className="flex flex-col items-center gap-2 p-3 rounded-2xl bg-card/60 border border-border/50 active:scale-95 transition-all touch-manipulation hover:bg-card"
            >
              <div className={`flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br ${action.color} shadow-md`}>
                <action.icon className="h-5 w-5 text-white" />
              </div>
              <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">
                {action.label}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Trending */}
      <div>
        <div className="flex items-center gap-2 mb-3">
          <TrendingUp className="h-4 w-4 text-primary" />
          <h2 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80">
            Tendances
          </h2>
        </div>
        <div className="space-y-2">
          {TRENDING.map((item) => (
            <div
              key={item.title}
              className="flex items-center gap-3 p-3 rounded-2xl bg-card/40 border border-border/30 active:bg-card/60 transition-all touch-manipulation"
            >
              <div className="flex-1 min-w-0">
                <h3 className="text-sm font-medium text-foreground truncate">
                  {item.title}
                </h3>
                <p className="text-xs text-muted-foreground">
                  par {item.author}
                </p>
              </div>
              <span className="text-xs font-medium text-primary bg-primary/10 px-2 py-1 rounded-full">
                ❤️ {item.likes}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div className="rounded-2xl bg-gradient-to-r from-primary to-accent p-5 text-center">
        <h3 className="text-white font-bold text-lg mb-1">
          Rejoins la communauté
        </h3>
        <p className="text-white/80 text-xs mb-3">
          Partage tes créations avec des milliers d'artistes
        </p>
        <button className="bg-white/90 text-primary font-semibold text-sm px-6 py-2.5 rounded-xl active:scale-95 transition-all touch-manipulation">
          Créer mon compte
        </button>
      </div>
    </div>
  );
}