import { Sparkles } from "lucide-react";
import { ImageWithFallback } from "./ImageWithFallback";
import {
  type Category,
  type CategorySlug,
  type SectionId,
} from "../data/community";

interface HeroProps {
  categories: Category[];
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function Hero({ categories, onNavigate }: HeroProps) {
  return (
    <section
      id="hero"
      className="relative flex min-h-[70vh] items-center justify-center overflow-hidden scroll-mt-28"
    >
      <div className="absolute inset-0 opacity-20">
        <ImageWithFallback
          src="https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080"
          alt="Abstract art background"
          className="h-full w-full object-cover"
        />
      </div>

      <div className="absolute inset-0 bg-gradient-to-b from-background via-background/50 to-background" />
      <div className="absolute inset-0 bg-gradient-to-r from-primary/10 via-secondary/10 to-accent/10" />

      <div className="absolute left-10 top-20 h-32 w-32 animate-pulse rounded-full border-2 border-primary/30" />
      <div className="absolute bottom-32 right-20 h-24 w-24 rotate-45 border-2 border-secondary/30" />
      <div className="absolute right-32 top-40 h-16 w-16 rounded-full bg-accent/20 blur-xl" />

      <div className="relative z-10 mx-auto max-w-5xl px-6 text-center">
        <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-4 py-2">
          <Sparkles className="h-4 w-4 text-primary" />
          <span className="text-sm font-medium text-primary">
            L'univers des créateurs indépendants
          </span>
        </div>

        <h1 className="mb-6 bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-5xl font-display italic leading-tight text-transparent md:text-7xl">
          Où l'art prend vie
        </h1>

        <p className="mx-auto mb-8 max-w-3xl text-xl font-accent italic text-muted-foreground md:text-2xl">
          Musique, manga, films, littérature et animation : chaque univers mène
          vers des artistes, des œuvres et des conversations reliées entre
          elles.
        </p>

        <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
          <button
            className="rounded-lg bg-primary px-8 py-4 font-medium text-primary-foreground shadow-lg shadow-primary/20 transition-all hover:opacity-90"
            onClick={() => onNavigate("categories", "all")}
          >
            Explorez l'univers
          </button>
          <button
            className="rounded-lg border border-border bg-card/50 px-8 py-4 font-medium text-foreground backdrop-blur transition-all hover:bg-card"
            onClick={() => onNavigate("join")}
          >
            Partagez votre art
          </button>
        </div>

        <div className="mt-10 flex flex-wrap items-center justify-center gap-3">
          {categories.map((category) => (
            <button
              key={category.slug}
              className="rounded-full border border-border bg-background/60 px-4 py-2 text-sm text-muted-foreground transition-colors hover:border-primary hover:text-primary"
              onClick={() =>
                onNavigate(category.targetSectionId, category.slug)
              }
            >
              {category.title}
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
