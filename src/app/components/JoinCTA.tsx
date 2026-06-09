import { Sparkles, ArrowRight } from 'lucide-react';

export function JoinCTA() {
  return (
    <section className="py-32 px-6 relative overflow-hidden">
      {/* Decorative background */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary/10 via-secondary/10 to-accent/10" />
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-primary to-transparent" />
      <div className="absolute bottom-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-secondary to-transparent" />

      {/* Ornamental elements */}
      <div className="absolute top-10 left-10 w-24 h-24 border-2 border-primary/20 rounded-full" />
      <div className="absolute bottom-10 right-10 w-32 h-32 border-2 border-secondary/20" style={{ transform: 'rotate(45deg)' }} />
      <div className="absolute top-1/2 left-1/4 w-16 h-16 border-2 border-accent/20 rounded-full" />

      <div className="relative max-w-4xl mx-auto text-center">
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary/10 border border-primary/30 rounded-full mb-8">
          <Sparkles className="w-4 h-4 text-primary" />
          <span className="text-sm text-primary font-medium">Rejoignez la révolution artistique</span>
        </div>

        <h2 className="text-5xl md:text-7xl font-display italic mb-6 bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent leading-tight">
          Votre art mérite d'être vu
        </h2>

        <p className="text-xl md:text-2xl text-muted-foreground max-w-2xl mx-auto mb-12 font-accent italic">
          Rejoignez des milliers de créateurs qui partagent leur passion, reçoivent des retours constructifs
          et trouvent leur public. L'art n'attend que vous.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16">
          <button className="group px-8 py-4 bg-primary text-primary-foreground rounded-lg hover:opacity-90 transition-all font-medium shadow-lg shadow-primary/20 flex items-center gap-2">
            <span>Créer mon compte gratuitement</span>
            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
          </button>
          <button className="px-8 py-4 border border-border bg-card/50 backdrop-blur text-foreground rounded-lg hover:bg-card transition-all font-medium">
            Découvrir les œuvres
          </button>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 max-w-3xl mx-auto">
          <StatCard number="12K+" label="Artistes actifs" />
          <StatCard number="45K+" label="Œuvres publiées" />
          <StatCard number="2M+" label="Discussions" />
          <StatCard number="98%" label="Satisfaction" />
        </div>
      </div>
    </section>
  );
}

function StatCard({ number, label }: { number: string; label: string }) {
  return (
    <div className="text-center">
      <div className="text-3xl md:text-4xl font-display text-primary mb-2">{number}</div>
      <div className="text-sm text-muted-foreground">{label}</div>
    </div>
  );
}
