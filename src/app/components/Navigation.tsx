import { Database, Palette, User } from "lucide-react";
import {
  type CategorySlug,
  type SectionId,
  categoryLabels,
  navigationItems,
} from "../data/community";
import { openStaticPage } from "../lib/page-links";

interface NavigationProps {
  selectedCategory: CategorySlug;
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function Navigation({ selectedCategory, onNavigate }: NavigationProps) {
  return (
    <nav className="fixed left-0 right-0 top-0 z-50 border-b border-border bg-background/80 backdrop-blur-xl">
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-6 py-4">
        <button
          className="flex items-center gap-3"
          onClick={() => onNavigate("hero")}
        >
          <div className="flex h-11 w-11 -rotate-3 items-center justify-center rounded-2xl border border-foreground/10 bg-gradient-to-br from-primary via-primary to-accent shadow-[0_12px_30px_rgba(255,106,26,0.25)]">
            <Palette className="h-6 w-6 text-primary-foreground" />
          </div>
          <div className="text-left">
            <h1 className="font-display text-2xl uppercase tracking-[0.18em] text-foreground">
              Artéïa
            </h1>
            <p className="hidden text-[11px] uppercase tracking-[0.24em] text-muted-foreground md:block">
              {categoryLabels[selectedCategory]}
            </p>
          </div>
        </button>

        <div className="hidden items-center gap-4 md:flex lg:gap-6">
          {navigationItems.map((item) => (
            <button
              key={item.label}
              className="group flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground transition-colors hover:text-foreground"
              onClick={() => {
                if (item.sectionId === "forum") {
                  openStaticPage("community");
                  return;
                }

                onNavigate(item.sectionId, item.category);
              }}
            >
              <span className="group-hover:text-primary transition-colors">
                {item.label}
              </span>
            </button>
          ))}
        </div>

        <div className="flex items-center gap-3">
          <button
            className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-primary hover:text-primary md:block"
            onClick={() => openStaticPage("login")}
          >
            Connexion
          </button>
          <button
            className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-accent hover:text-accent md:block"
            onClick={() => openStaticPage("database")}
          >
            <span className="inline-flex items-center gap-2">
              <Database className="h-4 w-4" />
              Base
            </span>
          </button>
          <button
            className="flex items-center gap-2 rounded-xl border border-primary/30 bg-primary px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-primary-foreground shadow-[0_10px_30px_rgba(255,106,26,0.25)] transition-all hover:-translate-y-0.5 hover:shadow-[0_14px_36px_rgba(255,106,26,0.35)]"
            onClick={() => openStaticPage("profile")}
          >
            <User className="h-4 w-4" />
            <span>Profil</span>
          </button>
        </div>
      </div>
    </nav>
  );
}
