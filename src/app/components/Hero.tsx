import { Sparkles } from "lucide-react";
import { ImageWithFallback } from "./ImageWithFallback";
import {
  type Category,
  type CategorySlug,
  type SectionId,
} from "../data/community";
import { openCategoryPage, openStaticPage } from "../lib/page-links";

const cinematicHeroScene =
  "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=cinematic%20snow-covered%20japanese%20village%20courtyard%20at%20dusk%2C%20lone%20swordsman%20seen%20from%20behind%2C%20child%20nearby%2C%20wind-blown%20snow%2C%20wet%20ground%2C%20atmospheric%20fog%2C%20subtle%20film%20grain%2C%20grounded%20composition%2C%20natural%20lighting%2C%20high-end%20editorial%20key%20art%2C%20beautiful%20and%20believable%2C%20not%20over-stylized%2C%20premium%20website%20hero%20background&image_size=landscape_16_9";

const snowParticles = Array.from({ length: 26 }, (_, index) => ({
  id: index,
  left: `${(index * 17) % 100}%`,
  size: 4 + (index % 5) * 3,
  duration: 14 + (index % 6) * 3,
  delay: (index % 7) * -2,
  opacity: 0.14 + (index % 4) * 0.08,
 }));

interface HeroProps {
  categories: Category[];
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function Hero({ categories, onNavigate }: HeroProps) {
  return (
    <section
      id="hero"
      className="relative flex min-h-[82vh] items-center justify-center overflow-hidden px-6 scroll-mt-28"
    >
      <div className="absolute inset-0">
        <ImageWithFallback
          src={cinematicHeroScene}
          alt="Scene cinematographique enneigee"
          className="animate-hero-pan h-full w-full object-cover object-center"
        />
      </div>
      <div className="absolute inset-0 opacity-20 mix-blend-screen">
        <ImageWithFallback
          src="https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080"
          alt="Texture atmospherique"
          className="animate-hero-float h-full w-full object-cover"
        />
      </div>

      <div className="absolute inset-0 bg-gradient-to-b from-background/45 via-background/55 to-background" />
      <div className="absolute inset-0 bg-[linear-gradient(120deg,rgba(255,106,26,0.22),transparent_34%,rgba(40,216,255,0.1)_67%,transparent)]" />
      <div className="hero-noise absolute inset-0 opacity-20" />
      <div className="absolute inset-x-0 bottom-0 h-32 bg-[linear-gradient(180deg,transparent,rgba(9,9,13,0.95))]" />

      <div className="absolute left-[8%] top-24 h-32 w-32 rotate-6 border border-primary/30 bg-primary/10 shadow-[0_0_50px_rgba(255,106,26,0.18)]" />
      <div className="absolute bottom-32 right-[10%] h-24 w-24 -rotate-12 border border-secondary/30 bg-secondary/10" />
      <div className="absolute right-32 top-40 h-20 w-20 rounded-full bg-accent/20 blur-2xl" />
      <div className="absolute inset-0 overflow-hidden">
        {snowParticles.map((particle) => (
          <span
            key={particle.id}
            className="animate-snowfall absolute top-[-10%] rounded-full bg-white"
            style={{
              left: particle.left,
              width: `${particle.size}px`,
              height: `${particle.size}px`,
              opacity: particle.opacity,
              animationDuration: `${particle.duration}s`,
              animationDelay: `${particle.delay}s`,
              filter: "blur(0.4px)",
            }}
          />
        ))}
      </div>

      <div className="relative z-10 mx-auto max-w-6xl">
        <div className="street-panel relative overflow-hidden px-8 py-12 text-center md:px-14 md:py-16">
          <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-transparent via-primary to-transparent" />
          <div className="absolute left-0 top-0 h-full w-24 bg-[linear-gradient(180deg,rgba(255,106,26,0.18),transparent)]" />
          <div className="absolute bottom-0 right-0 h-full w-32 bg-[linear-gradient(180deg,transparent,rgba(40,216,255,0.1))]" />
          <div className="mb-7 inline-flex -rotate-1 items-center gap-2 rounded-md border border-primary/35 bg-background/60 px-4 py-2 shadow-[0_10px_30px_rgba(0,0,0,0.18)]">
          <Sparkles className="h-4 w-4 text-primary" />
          <span className="text-xs font-semibold uppercase tracking-[0.26em] text-primary">
            Une entree qui vit avec toi
          </span>
        </div>

          <h1 className="street-title mb-6 text-5xl leading-[0.95] md:text-7xl xl:text-[5.5rem]">
            ENTRE
            <span className="mx-3 inline-block text-primary">DANS</span>
            L'UNIVERS
          </h1>

          <p className="street-copy mx-auto mb-10 max-w-3xl text-lg leading-8 md:text-2xl">
            Une scene vivante, du souffle, de la neige, du silence, de la
            tension. Ici le projet te parle des la premiere seconde et donne
            l'impression qu'un monde existe deja derriere l'ecran.
          </p>

          <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
            <button
              className="rounded-xl border border-primary/30 bg-primary px-8 py-4 text-sm font-semibold uppercase tracking-[0.2em] text-primary-foreground shadow-[0_16px_40px_rgba(255,106,26,0.28)] transition-all hover:-translate-y-1 hover:shadow-[0_20px_46px_rgba(255,106,26,0.36)]"
              onClick={() => onNavigate("categories", "all")}
            >
              Explorer l'univers
            </button>
            <button
              className="rounded-xl border border-border bg-background/60 px-8 py-4 text-sm font-semibold uppercase tracking-[0.2em] text-foreground backdrop-blur transition-all hover:border-accent hover:text-accent"
              onClick={() => openStaticPage("database")}
            >
              Voir la base
            </button>
          </div>

          <div className="mt-10 flex flex-wrap items-center justify-center gap-3">
            {categories.map((category) => (
              <button
                key={category.slug}
                className="street-chip transition-colors hover:border-primary hover:text-primary"
                onClick={() => openCategoryPage(category.slug)}
              >
                {category.title}
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
