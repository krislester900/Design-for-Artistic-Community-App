import { ImageWithFallback } from './ImageWithFallback';
import { Play, Heart, Share2 } from 'lucide-react';

const artists = [
  {
    name: 'Akira Sato',
    category: 'Mangaka',
    image: 'https://images.unsplash.com/photo-1777645948844-24859533196e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwzfHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080',
    work: 'Les Ombres du Crépuscule',
    likes: 2847
  },
  {
    name: 'Maya Dubois',
    category: 'Compositrice',
    image: 'https://images.unsplash.com/photo-1770739520456-5fb5df8b25fc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwzfHxzdHJlZXQlMjBhcnQlMjBncmFmZml0aSUyMHZpY3RvcmlhbiUyMGFyY2hpdGVjdHVyZXxlbnwxfHx8fDE3ODA5OTYzMTB8MA&ixlib=rb-4.1.0&q=80&w=1080',
    work: 'Symphonie Urbaine Vol.3',
    likes: 3921
  },
  {
    name: 'Lucas Stone',
    category: 'Cinéaste',
    image: 'https://images.unsplash.com/photo-1764023874407-acac56960791?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxzdHJlZXQlMjBhcnQlMjBncmFmZml0aSUyMHZpY3RvcmlhbiUyMGFyY2hpdGVjdHVyZXxlbnwxfHx8fDE3ODA5OTYzMTB8MA&ixlib=rb-4.1.0&q=80&w=1080',
    work: 'Le Dernier Métro',
    likes: 1654
  },
  {
    name: 'Amélie Laurent',
    category: 'Illustratrice',
    image: 'https://images.unsplash.com/photo-1762860498297-4b6c3591b041?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw0fHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080',
    work: 'Jardins de Soie',
    likes: 4182
  }
];

export function FeaturedArtists() {
  return (
    <section className="py-20 px-6 bg-gradient-to-b from-background via-card/20 to-background">
      <div className="max-w-7xl mx-auto">
        <div className="flex items-end justify-between mb-12">
          <div>
            <h2 className="text-4xl md:text-5xl font-display italic mb-2">
              Artistes en lumière
            </h2>
            <p className="text-muted-foreground font-accent italic">
              Découvrez les créateurs qui façonnent notre communauté
            </p>
          </div>
          <button className="hidden md:block px-6 py-3 border border-border rounded-lg hover:border-primary hover:text-primary transition-colors">
            Voir tous les artistes
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {artists.map((artist, index) => (
            <ArtistCard key={index} {...artist} />
          ))}
        </div>
      </div>
    </section>
  );
}

function ArtistCard({
  name,
  category,
  image,
  work,
  likes
}: {
  name: string;
  category: string;
  image: string;
  work: string;
  likes: number;
}) {
  return (
    <div className="group relative rounded-xl overflow-hidden border border-border bg-card hover:border-primary/50 transition-all duration-300">
      <div className="relative aspect-[3/4] overflow-hidden">
        <ImageWithFallback
          src={image}
          alt={name}
          className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/60 to-transparent" />

        <button className="absolute top-4 right-4 w-10 h-10 rounded-full bg-background/80 backdrop-blur-sm border border-border flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hover:bg-primary hover:text-primary-foreground">
          <Play className="w-4 h-4 ml-0.5" />
        </button>

        <div className="absolute bottom-0 left-0 right-0 p-6">
          <span className="inline-block px-3 py-1 bg-primary/20 border border-primary/30 rounded-full text-xs text-primary mb-3">
            {category}
          </span>
          <h3 className="text-xl font-display mb-1">{name}</h3>
          <p className="text-sm text-muted-foreground font-accent italic mb-4">
            {work}
          </p>

          <div className="flex items-center gap-4">
            <button className="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors">
              <Heart className="w-4 h-4" />
              <span>{likes.toLocaleString()}</span>
            </button>
            <button className="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors">
              <Share2 className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
