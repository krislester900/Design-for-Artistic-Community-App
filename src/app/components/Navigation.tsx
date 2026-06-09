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
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
        <button
          className="flex items-center gap-3"
          onClick={() => onNavigate("hero")}
        >
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-primary via-secondary to-accent">
            <Palette className="h-6 w-6 text-primary-foreground" />
          </div>
          <div className="text-left">
            <h1 className="text-2xl font-display italic tracking-wide text-primary">
              Artéïa
            </h1>
            <p className="hidden text-xs text-muted-foreground md:block">
              {categoryLabels[selectedCategory]}
            </p>
          </div>
        </button>

        <div className="hidden items-center gap-4 md:flex lg:gap-6">
          {navigationItems.map((item) => (
            <button
              key={item.label}
              className="group flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
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
            className="hidden rounded-lg border border-border px-4 py-2 text-sm transition-colors hover:border-primary hover:text-primary md:block"
            onClick={() => openStaticPage("database")}
          >
            <span className="inline-flex items-center gap-2">
              <Database className="h-4 w-4" />
              Base
            </span>
          </button>
          <button
            className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-primary-foreground transition-opacity hover:opacity-90"
            onClick={() => onNavigate("join")}
          >
            <User className="h-4 w-4" />
            <span>Profil</span>
          </button>
        </div>
      </div>
    </nav>
  );
}
