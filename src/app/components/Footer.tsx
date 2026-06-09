import { Palette, Compass, MessageCircle, Sparkles } from "lucide-react";
import {
  footerSections,
  getCategoryLabel,
  type CategorySlug,
  type SectionId,
} from "../data/community";

interface FooterProps {
  selectedCategory: CategorySlug;
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function Footer({ selectedCategory, onNavigate }: FooterProps) {
  return (
    <footer className="border-t border-border bg-card/50 backdrop-blur">
      <div className="mx-auto max-w-7xl px-6 py-16">
        <div className="mb-12 grid grid-cols-1 gap-12 md:grid-cols-2 lg:grid-cols-4">
          <div>
            <button
              className="mb-4 flex items-center gap-3"
              onClick={() => onNavigate("hero")}
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-primary via-secondary to-accent">
                <Palette className="h-6 w-6 text-primary-foreground" />
              </div>
              <h3 className="text-2xl font-display italic tracking-wide text-primary">
                Artéïa
              </h3>
            </button>
            <p className="mb-6 font-accent italic text-muted-foreground">
              Une plateforme artistique où chaque univers est connecté aux
              créateurs, aux œuvres et aux discussions de la communauté.
            </p>
            <div className="mb-4 rounded-xl border border-border bg-background/60 p-4 text-sm text-muted-foreground">
              Univers actif :{" "}
              <span className="font-medium text-foreground">
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
                onClick={() => onNavigate("forum", selectedCategory)}
              />
              <QuickAction
                icon={<Sparkles className="h-5 w-5" />}
                label="Rejoindre"
                onClick={() => onNavigate("join", selectedCategory)}
              />
            </div>
          </div>

          {footerSections.map((section) => (
            <div key={section.title}>
              <h4 className="mb-4 text-lg font-display">{section.title}</h4>
              <ul className="space-y-3">
                {section.links.map((link) => (
                  <FooterLink
                    key={link.text}
                    text={link.text}
                    onClick={() => onNavigate(link.sectionId, link.category)}
                  />
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="flex flex-col items-center justify-between gap-4 border-t border-border pt-8 md:flex-row">
          <p className="text-sm text-muted-foreground">
            © 2026 Artéïa. Tous droits réservés. Une expérience cohérente pour
            les créateurs.
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
              onClick={() => onNavigate("showcase", selectedCategory)}
            >
              Continuer l'exploration
            </button>
            <button
              className="transition-colors hover:text-primary"
              onClick={() => onNavigate("join", selectedCategory)}
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
      className="flex h-10 w-10 items-center justify-center rounded-lg border border-border bg-background transition-all hover:border-primary hover:bg-primary hover:text-primary-foreground"
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
        className="text-muted-foreground transition-colors hover:text-primary"
        onClick={onClick}
      >
        {text}
      </button>
    </li>
  );
}
