import { Sparkles, ArrowRight } from "lucide-react";
import {
  type CategorySlug,
  type CommunityStat,
  type SectionId,
} from "../data/community";
import { openStaticPage } from "../lib/page-links";

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
      <div className="absolute inset-0 bg-gradient-to-br from-primary/12 via-background to-accent/12" />
      <div className="absolute left-0 top-0 h-1 w-full bg-gradient-to-r from-transparent via-primary to-transparent" />
      <div className="absolute bottom-0 left-0 h-1 w-full bg-gradient-to-r from-transparent via-accent to-transparent" />

      <div className="absolute left-10 top-10 h-24 w-24 rounded-full border-2 border-primary/20" />
      <div
        className="absolute bottom-10 right-10 h-32 w-32 border-2 border-secondary/20"
        style={{ transform: "rotate(45deg)" }}
      />
      <div className="absolute left-1/4 top-1/2 h-16 w-16 rounded-full border-2 border-accent/20" />

      <div className="street-panel relative mx-auto max-w-5xl overflow-hidden px-8 py-14 text-center md:px-14">
        <div className="absolute right-0 top-0 h-full w-28 bg-[linear-gradient(180deg,rgba(40,216,255,0.12),transparent)]" />
        <div className="mb-8 inline-flex -rotate-1 items-center gap-2 rounded-md border border-primary/30 bg-background/70 px-4 py-2">
          <Sparkles className="h-4 w-4 text-primary" />
          <span className="text-xs font-semibold uppercase tracking-[0.28em] text-primary">
            Rejoignez la révolution artistique
          </span>
        </div>

        <h2 className="street-title mb-6 text-5xl leading-[0.95] md:text-7xl">
          Votre art merite
          <span className="mx-3 inline-block text-secondary">de claquer</span>
          fort
        </h2>

        <p className="street-copy mx-auto mb-12 max-w-2xl text-xl leading-8 md:text-2xl">
          Rejoignez des milliers de créateurs qui partagent leur passion,
          reçoivent des retours constructifs et trouvent leur public.
        </p>

        <div className="mb-16 flex flex-col items-center justify-center gap-4 sm:flex-row">
          <button
            className="group flex items-center gap-2 rounded-xl border border-primary/30 bg-primary px-8 py-4 text-sm font-semibold uppercase tracking-[0.18em] text-primary-foreground shadow-[0_16px_40px_rgba(255,106,26,0.28)] transition-all hover:-translate-y-1"
            onClick={() => openStaticPage("signup")}
          >
            <span>Créer mon compte gratuitement</span>
            <ArrowRight className="h-5 w-5 transition-transform group-hover:translate-x-1" />
          </button>
          <button
            className="rounded-xl border border-border bg-background/60 px-8 py-4 text-sm font-semibold uppercase tracking-[0.18em] text-foreground backdrop-blur transition-all hover:border-accent hover:text-accent"
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
    <div className="street-panel-soft px-3 py-5 text-center">
      <div className="street-title mb-2 text-3xl text-primary md:text-4xl">
        {number}
      </div>
      <div className="text-xs uppercase tracking-[0.16em] text-muted-foreground">
        {label}
      </div>
    </div>
  );
}
