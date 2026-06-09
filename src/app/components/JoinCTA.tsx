import { Sparkles, ArrowRight } from "lucide-react";
import {
  type CategorySlug,
  type CommunityStat,
  type SectionId,
} from "../data/community";

interface JoinCTAProps {
  communityStats: CommunityStat[];
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function JoinCTA({ communityStats, onNavigate }: JoinCTAProps) {
  return (
    <section
      id="join"
      className="relative overflow-hidden px-6 py-32 scroll-mt-28"
    >
      <div className="absolute inset-0 bg-gradient-to-br from-primary/10 via-secondary/10 to-accent/10" />
      <div className="absolute left-0 top-0 h-1 w-full bg-gradient-to-r from-transparent via-primary to-transparent" />
      <div className="absolute bottom-0 left-0 h-1 w-full bg-gradient-to-r from-transparent via-secondary to-transparent" />

      <div className="absolute left-10 top-10 h-24 w-24 rounded-full border-2 border-primary/20" />
      <div
        className="absolute bottom-10 right-10 h-32 w-32 border-2 border-secondary/20"
        style={{ transform: "rotate(45deg)" }}
      />
      <div className="absolute left-1/4 top-1/2 h-16 w-16 rounded-full border-2 border-accent/20" />

      <div className="relative mx-auto max-w-4xl text-center">
        <div className="mb-8 inline-flex items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-4 py-2">
          <Sparkles className="h-4 w-4 text-primary" />
          <span className="text-sm font-medium text-primary">
            Rejoignez la révolution artistique
          </span>
        </div>

        <h2 className="mb-6 bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-5xl font-display italic leading-tight text-transparent md:text-7xl">
          Votre art mérite d'être vu
        </h2>

        <p className="mx-auto mb-12 max-w-2xl text-xl font-accent italic text-muted-foreground md:text-2xl">
          Rejoignez des milliers de créateurs qui partagent leur passion,
          reçoivent des retours constructifs et trouvent leur public.
        </p>

        <div className="mb-16 flex flex-col items-center justify-center gap-4 sm:flex-row">
          <button
            className="group flex items-center gap-2 rounded-lg bg-primary px-8 py-4 font-medium text-primary-foreground shadow-lg shadow-primary/20 transition-all hover:opacity-90"
            onClick={() => onNavigate("join")}
          >
            <span>Créer mon compte gratuitement</span>
            <ArrowRight className="h-5 w-5 transition-transform group-hover:translate-x-1" />
          </button>
          <button
            className="rounded-lg border border-border bg-card/50 px-8 py-4 font-medium text-foreground backdrop-blur transition-all hover:bg-card"
            onClick={() => onNavigate("showcase")}
          >
            Découvrir les œuvres
          </button>
        </div>

        <div className="mx-auto grid max-w-3xl grid-cols-2 gap-8 md:grid-cols-4">
          {communityStats.map((stat) => (
            <StatCard
              key={stat.label}
              number={stat.number}
              label={stat.label}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

function StatCard({ number, label }: { number: string; label: string }) {
  return (
    <div className="text-center">
      <div className="mb-2 text-3xl font-display text-primary md:text-4xl">
        {number}
      </div>
      <div className="text-sm text-muted-foreground">{label}</div>
    </div>
  );
}
