import { useState } from "react";
import { Database, Palette, User, Menu, X } from "lucide-react";
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
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <>
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
              <h1 className="text-2xl uppercase tracking-[0.18em] text-foreground" style={{ fontFamily: "'Alien Block', cursive" }}>
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
            {/* Mobile hamburger */}
            <button
              className="flex items-center justify-center rounded-xl border border-border bg-card/60 p-2.5 md:hidden"
              onClick={() => setMobileOpen(!mobileOpen)}
              aria-label="Menu"
            >
              {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </button>
          </div>
        </div>
      </nav>

      {/* Mobile menu overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 z-[60] md:hidden" onClick={() => setMobileOpen(false)}>
          <div className="absolute inset-0 bg-background/80 backdrop-blur-sm" />
          <div
            className="absolute right-0 top-0 h-full w-72 border-l border-border bg-background/95 backdrop-blur-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between border-b border-border px-6 py-4">
              <span className="text-sm font-semibold uppercase tracking-[0.18em] text-foreground">Menu</span>
              <button onClick={() => setMobileOpen(false)} className="p-1">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-1 px-4 py-4">
              {navigationItems.map((item) => (
                <button
                  key={item.label}
                  className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold uppercase tracking-[0.14em] text-muted-foreground transition-colors hover:bg-primary/10 hover:text-primary"
                  onClick={() => {
                    setMobileOpen(false);
                    if (item.sectionId === "forum") {
                      openStaticPage("community");
                      return;
                    }
                    onNavigate(item.sectionId, item.category);
                  }}
                >
                  <span>{item.label}</span>
                </button>
              ))}
            </div>
            <div className="border-t border-border px-4 py-4 space-y-2">
              <button
                className="flex w-full items-center gap-3 rounded-xl border border-border bg-card/60 px-4 py-3 text-xs font-semibold uppercase tracking-[0.16em] text-foreground transition-colors hover:border-primary hover:text-primary"
                onClick={() => { setMobileOpen(false); openStaticPage("login"); }}
              >
                <Database className="h-4 w-4" />
                Connexion
              </button>
              <button
                className="flex w-full items-center gap-3 rounded-xl border border-primary/30 bg-primary px-4 py-3 text-xs font-semibold uppercase tracking-[0.16em] text-primary-foreground shadow-[0_8px_20px_rgba(255,106,26,0.2)]"
                onClick={() => { setMobileOpen(false); openStaticPage("profile"); }}
              >
                <User className="h-4 w-4" />
                Profil
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
