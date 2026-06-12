import {
  Database,
  Palette,
  Compass,
  MessageCircle,
  Sparkles,
} from "lucide-react";
import {
  footerSections,
  getCategoryLabel,
  type CategorySlug,
  type SectionId,
} from "../data/community";
import { openCategoryPage, openStaticPage } from "../lib/page-links";

interface FooterProps {
  selectedCategory: CategorySlug;
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function Footer({ selectedCategory, onNavigate }: FooterProps) {
  return (
    <footer className="border-t border-border bg-card/35 backdrop-blur">
      <div className="mx-auto max-w-7xl px-6 py-16">
        <div className="mb-12 grid grid-cols-1 gap-12 md:grid-cols-2 lg:grid-cols-4">
          <div>
            <button
              className="mb-4 flex items-center gap-3"
              onClick={() => onNavigate("hero")}
            >
              <div className="flex h-11 w-11 -rotate-3 items-center justify-center rounded-2xl border border-foreground/10 bg-gradient-to-br from-primary via-primary to-accent shadow-[0_12px_30px_rgba(255,106,26,0.22)]">
                <Palette className="h-6 w-6 text-primary-foreground" />
              </div>
              <h3 className="text-2xl uppercase tracking-[0.18em] text-foreground" style={{ fontFamily: "'Alien Block', cursive" }}>
                Artéïa
              </h3>
            </button>
            <p className="street-copy mb-6">
              Une plateforme artistique où chaque univers est connecté aux
              créateurs, aux œuvres et aux discussions de la communauté.
            </p>
            <div className="street-panel-soft mb-4 p-4 text-sm text-muted-foreground">
              Univers actif :{" "}
              <span className="font-semibold uppercase tracking-[0.14em] text-foreground">
                {getCategoryLabel(selectedCategory)}
              </span>
            </div>
            <div className="flex items-center gap-3">
              <QuickAction
                icon={<Compass className="h-5 w-5" />}
                label="Explorer"
                onClick={() => onNavigate("categories")}
              />
              <QuickAction
                icon={<MessageCircle className="h-5 w-5" />}
                label="Forum"
                onClick={() => openStaticPage("community")}
              />
              <QuickAction
                icon={<Sparkles className="h-5 w-5" />}
                label="Rejoindre"
                onClick={() => openStaticPage("signup")}
              />
              <QuickAction
                icon={<Database className="h-5 w-5" />}
                label="Base"
                onClick={() => openStaticPage("database")}
              />
            </div>
          </div>

          {footerSections.map((section) => (
            <div key={section.title}>
              <h4 className="street-title mb-4 text-lg">{section.title}</h4>
              <ul className="space-y-3">
                {section.links.map((link) => (
                  <FooterLink
                    key={link.text}
                    text={link.text}
                    onClick={() => {
                      if (link.category && link.category !== "all") {
                        openCategoryPage(link.category);
                        return;
                      }

                      onNavigate(link.sectionId, link.category);
                    }}
                  />
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="flex flex-col items-center justify-between gap-4 border-t border-border pt-8 md:flex-row">
          <p className="text-sm uppercase tracking-[0.12em] text-muted-foreground">
            © 2026 Artéïa. Cree par Kris N'dri sous l'inspiration de Fatmé
            Sleiman.
          </p>
          <div className="flex items-center gap-6 text-sm text-muted-foreground">
            <button
              className="transition-colors hover:text-primary"
              onClick={() => onNavigate("categories", "all")}
            >
              Réinitialiser le parcours
            </button>
            <button
              className="transition-colors hover:text-primary"
              onClick={() => openStaticPage("database")}
            >
              Voir la base
            </button>
            <button
              className="transition-colors hover:text-primary"
              onClick={() => openStaticPage("profile")}
            >
              Publier mon projet
            </button>
          </div>
        </div>
      </div>
    </footer>
  );
}

function QuickAction({
  icon,
  label,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
}) {
  return (
    <button
      className="flex h-10 w-10 items-center justify-center rounded-xl border border-border bg-background transition-all hover:-translate-y-0.5 hover:border-primary hover:bg-primary hover:text-primary-foreground"
      aria-label={label}
      onClick={onClick}
    >
      {icon}
    </button>
  );
}

function FooterLink({ text, onClick }: { text: string; onClick: () => void }) {
  return (
    <li>
      <button
        className="text-sm uppercase tracking-[0.12em] text-muted-foreground transition-colors hover:text-primary"
        onClick={onClick}
      >
        {text}
      </button>
    </li>
  );
}
