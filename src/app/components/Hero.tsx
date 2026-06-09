import { Sparkles } from 'lucide-react';
import { ImageWithFallback } from './ImageWithFallback';

export function Hero() {
  return (
    <section className="relative min-h-[70vh] flex items-center justify-center overflow-hidden">
      {/* Background artistic texture */}
      <div className="absolute inset-0 opacity-20">
        <ImageWithFallback
          src="https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080"
          alt="Abstract art background"
          className="w-full h-full object-cover"
        />
      </div>

      {/* Gradient overlays */}
      <div className="absolute inset-0 bg-gradient-to-b from-background via-background/50 to-background" />
      <div className="absolute inset-0 bg-gradient-to-r from-primary/10 via-secondary/10 to-accent/10" />

      {/* Decorative elements */}
      <div className="absolute top-20 left-10 w-32 h-32 border-2 border-primary/30 rounded-full animate-pulse" />
      <div className="absolute bottom-32 right-20 w-24 h-24 border-2 border-secondary/30 rotate-45" />
      <div className="absolute top-40 right-32 w-16 h-16 bg-accent/20 rounded-full blur-xl" />

      <div className="relative z-10 max-w-5xl mx-auto px-6 text-center">
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary/10 border border-primary/30 rounded-full mb-6">
          <Sparkles className="w-4 h-4 text-primary" />
          <span className="text-sm text-primary font-medium">L'univers des créateurs indépendants</span>
        </div>

        <h1 className="text-5xl md:text-7xl font-display italic mb-6 bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent leading-tight">
          Où l'art prend vie
        </h1>

        <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto mb-8 font-accent italic">
          Musique, manga, films, littérature... Partagez vos créations, découvrez des univers uniques,
          et rejoignez une communauté passionnée par l'art sous toutes ses formes.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <button className="px-8 py-4 bg-primary text-primary-foreground rounded-lg hover:opacity-90 transition-all font-medium shadow-lg shadow-primary/20">
            Explorez l'univers
          </button>
          <button className="px-8 py-4 border border-border bg-card/50 backdrop-blur text-foreground rounded-lg hover:bg-card transition-all font-medium">
            Partagez votre art
          </button>
        </div>
      </div>
    </section>
  );
}
