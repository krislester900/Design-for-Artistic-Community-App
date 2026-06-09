import { Music, BookOpen, Film, Palette, Pen, Mic } from 'lucide-react';
import { ImageWithFallback } from './ImageWithFallback';

const categories = [
  {
    icon: Music,
    title: 'Musique',
    description: 'Partagez vos compositions, paroles et mélodies',
    image: 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwzfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-primary/20 to-primary/5'
  },
  {
    icon: Palette,
    title: 'Art Visuel',
    description: 'Exposez vos illustrations et créations graphiques',
    image: 'https://images.unsplash.com/photo-1618331833071-ce81bd50d300?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-secondary/20 to-secondary/5'
  },
  {
    icon: BookOpen,
    title: 'Manga & BD',
    description: 'Publiez vos planches et histoires illustrées',
    image: 'https://images.unsplash.com/photo-1763732397864-5b860bb298b0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-accent/20 to-accent/5'
  },
  {
    icon: Film,
    title: 'Films Indépendants',
    description: 'Découvrez et partagez des courts-métrages uniques',
    image: 'https://images.unsplash.com/photo-1618331835717-801e976710b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw0fHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-chart-4/20 to-chart-4/5'
  },
  {
    icon: Pen,
    title: 'Littérature',
    description: 'Écrivez et partagez vos textes poétiques et narratifs',
    image: 'https://images.unsplash.com/photo-1533208087231-c3618eab623c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw1fHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-chart-5/20 to-chart-5/5'
  },
  {
    icon: Mic,
    title: 'Animation',
    description: 'Présentez vos projets d\'animation et motion design',
    image: 'https://images.unsplash.com/photo-1779864535439-292f58c6c6a4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw1fHxzdHJlZXQlMjBhcnQlMjBncmFmZml0aSUyMHZpY3RvcmlhbiUyMGFyY2hpdGVjdHVyZXxlbnwxfHx8fDE3ODA5OTYzMTB8MA&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-primary/20 to-secondary/5'
  }
];

export function ArtCategories() {
  return (
    <section className="py-20 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-display italic mb-4">
            Explorez par univers
          </h2>
          <p className="text-lg text-muted-foreground font-accent italic">
            Chaque création trouve sa place dans notre galerie infinie
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {categories.map((category, index) => (
            <CategoryCard key={index} {...category} />
          ))}
        </div>
      </div>
    </section>
  );
}

function CategoryCard({
  icon: Icon,
  title,
  description,
  image,
  color
}: {
  icon: React.ElementType;
  title: string;
  description: string;
  image: string;
  color: string;
}) {
  return (
    <div className="group relative overflow-hidden rounded-xl border border-border bg-card hover:border-primary/50 transition-all duration-300 cursor-pointer">
      <div className="absolute inset-0 opacity-30 group-hover:opacity-40 transition-opacity">
        <ImageWithFallback
          src={image}
          alt={title}
          className="w-full h-full object-cover"
        />
      </div>

      <div className={`absolute inset-0 bg-gradient-to-br ${color}`} />

      <div className="relative p-6 min-h-[280px] flex flex-col justify-between">
        <div className="w-12 h-12 rounded-lg bg-primary/20 border border-primary/30 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
          <Icon className="w-6 h-6 text-primary" />
        </div>

        <div>
          <h3 className="text-2xl font-display mb-2">{title}</h3>
          <p className="text-muted-foreground">{description}</p>
        </div>

        <div className="mt-4 flex items-center gap-2 text-primary opacity-0 group-hover:opacity-100 transition-opacity">
          <span className="text-sm font-medium">Explorer</span>
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </div>
      </div>
    </div>
  );
}
