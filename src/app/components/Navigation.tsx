import { useState } from "react";
import { Link } from "react-router-dom";
import { Database, Gamepad2, Inbox, Menu, Music, Palette, User, Workflow, X } from "lucide-react";
import {
  type CategorySlug,
  type SectionId,
  categoryLabels,
  navigationItems,
} from "../data/community";
import { openStaticPage, getStaticPagePath } from "../lib/page-links";

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
            className="group flex items-center gap-3"
            onClick={() => onNavigate("hero")}
          >
            <div className="flex h-11 w-11 items-center justify-center rounded-full border border-foreground/20 bg-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] transition-all duration-500 group-hover:shadow-[0_0_25px_rgba(0,0,0,0.2)] group-hover:scale-110 dark:shadow-[0_0_15px_rgba(255,255,255,0.1)] dark:group-hover:shadow-[0_0_25px_rgba(255,255,255,0.2)]">
              <span className="text-background font-black text-lg dark:text-foreground" style={{ fontFamily: "'Alien Block', cursive" }}>A</span>
            </div>
            <div className="text-left">
              <h1 className="text-foreground text-2xl uppercase tracking-[0.18em]" style={{ fontFamily: "'Alien Block', cursive" }}>
                Arteïa
              </h1>
              <p className="hidden text-[11px] uppercase tracking-[0.24em] text-muted-foreground md:block">
                {categoryLabels[selectedCategory]}
              </p>
            </div>
          </button>

          <div className="hidden items-center gap-4 md:flex lg:gap-6">
            {navigationItems.map((item) => (
              item.sectionId === "forum" ? (
                <Link
                  key={item.label}
                  to="/community"
                  className="group flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground transition-colors hover:text-foreground"
                >
                  <span className="transition-colors group-hover:text-primary">
                    {item.label}
                  </span>
                </Link>
              ) : (
                <button
                  key={item.label}
                  className="group flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground transition-colors hover:text-foreground"
                  onClick={() => onNavigate(item.sectionId, item.category)}
                >
                  <span className="transition-colors group-hover:text-primary">
                    {item.label}
                  </span>
                </button>
              )
            ))}
            <Link
              to="/database"
              className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-accent hover:text-accent md:block"
            >
              <span className="inline-flex items-center gap-2">
                <Database className="h-4 w-4" />
                Base de données
              </span>
            </Link>
            <Link
              to={getStaticPagePath("games")}
              className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-primary hover:text-primary md:block"
            >
              <span className="inline-flex items-center gap-2">
                <Gamepad2 className="h-4 w-4" />
                Jeux
              </span>
            </Link>
            <Link
              to="/music-vynora"
              className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-primary hover:text-primary md:block"
            >
              <span className="inline-flex items-center gap-2">
                <Music className="h-4 w-4" />
                Musique
              </span>
            </Link>
            <Link
              to="/muse-carousel"
              className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-primary hover:text-primary md:block"
            >
              <span className="inline-flex items-center gap-2">
                <Workflow className="h-4 w-4" />
                Card Stack
              </span>
            </Link>
          </div>

          <div className="flex items-center gap-3">
            <Link
              to="/inbox"
              className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-blue-500 hover:text-blue-500 md:block"
            >
              <span className="inline-flex items-center gap-2">
                <Inbox className="h-4 w-4" />
                Messages
              </span>
            </Link>
            <Link
              to="/database"
              className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-accent hover:text-accent md:block"
            >
              <span className="inline-flex items-center gap-2">
                <Database className="h-4 w-4" />
                Base
              </span>
            </Link>
            <Link
              to="/ontology"
              className="hidden rounded-xl border border-border bg-card/60 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-violet-500 hover:text-violet-500 md:block"
            >
              <span className="inline-flex items-center gap-2">
                <Workflow className="h-4 w-4" />
                Ontologie
              </span>
            </Link>
            <Link
              to="/profile"
              className="flex items-center gap-2 rounded-xl border border-primary/30 bg-primary px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-primary-foreground shadow-[0_10px_30px_rgba(255,106,26,0.25)] transition-all hover:-translate-y-0.5 hover:shadow-[0_14px_36px_rgba(255,106,26,0.35)]"
            >
              <User className="h-4 w-4" />
              <span>Profil</span>
            </Link>
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

      {mobileOpen && (
        <div className="fixed inset-0 z-[60] md:hidden" onClick={() => setMobileOpen(false)}>
          <div className="absolute inset-0 bg-background/80 backdrop-blur-sm" />
          <div
            className="absolute right-0 top-0 h-full w-72 border-l border-border bg-background/95 backdrop-blur-xl"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="flex items-center justify-between border-b border-border px-6 py-4">
              <span className="text-sm font-semibold uppercase tracking-[0.18em] text-foreground">Menu</span>
              <button onClick={() => setMobileOpen(false)} className="p-1">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-1 px-4 py-4">
              {navigationItems.map((item) => (
                item.sectionId === "forum" ? (
                  <Link
                    key={item.label}
                    to="/community"
                    className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold uppercase tracking-[0.14em] text-muted-foreground transition-colors hover:bg-primary/10 hover:text-primary"
                    onClick={() => setMobileOpen(false)}
                  >
                    <span>{item.label}</span>
                  </Link>
                ) : (
                  <button
                    key={item.label}
                    className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold uppercase tracking-[0.14em] text-muted-foreground transition-colors hover:bg-primary/10 hover:text-primary"
                    onClick={() => {
                      setMobileOpen(false);
                      onNavigate(item.sectionId, item.category);
                    }}
                  >
                    <span>{item.label}</span>
                  </button>
                )
              ))}
            </div>
            <div className="space-y-2 border-t border-border px-4 py-4">
              <Link
                to="/login"
                className="flex w-full items-center gap-3 rounded-xl border border-border bg-card/60 px-4 py-3 text-xs font-semibold uppercase tracking-[0.16em] text-foreground transition-colors hover:border-primary hover:text-primary"
                onClick={() => setMobileOpen(false)}
              >
                <Database className="h-4 w-4" />
                Connexion
              </Link>
              <Link
                to="/profile"
                className="flex w-full items-center gap-3 rounded-xl border border-primary/30 bg-primary px-4 py-3 text-xs font-semibold uppercase tracking-[0.16em] text-primary-foreground shadow-[0_8px_20px_rgba(255,106,26,0.2)]"
                onClick={() => setMobileOpen(false)}
              >
                <User className="h-4 w-4" />
                Profil
              </Link>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
