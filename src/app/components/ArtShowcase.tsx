import { ImageWithFallback } from './ImageWithFallback';
import { Heart, Eye, Bookmark } from 'lucide-react';

const artworks = [
  {
    image: 'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Émotions Abstraites',
    artist: 'Sophie Moreau',
    category: 'Peinture',
    likes: 1247,
    views: 8934,
    height: 'aspect-square'
  },
  {
    image: 'https://images.unsplash.com/photo-1618331833071-ce81bd50d300?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Rêves Urbains',
    artist: 'Marc Dubois',
    category: 'Digital',
    likes: 892,
    views: 5621,
    height: 'aspect-[3/4]'
  },
  {
    image: 'https://images.unsplash.com/photo-1763732397864-5b860bb298b0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Chronicles Vol. 1',
    artist: 'Yuki Tanaka',
    category: 'Manga',
    likes: 2103,
    views: 12450,
    height: 'aspect-[3/4]'
  },
  {
    image: 'https://images.unsplash.com/photo-1777645948844-24859533196e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwzfHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Masque Ancestral',
    artist: 'Kaito Nakamura',
    category: 'Encre',
    likes: 1567,
    views: 9234,
    height: 'aspect-square'
  },
  {
    image: 'https://images.unsplash.com/photo-1618331835717-801e976710b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw0fHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Couleurs de la Vie',
    artist: 'Emma Laurent',
    category: 'Acrylique',
    likes: 734,
    views: 4521,
    height: 'aspect-[4/3]'
  },
  {
    image: 'https://images.unsplash.com/photo-1762860498297-4b6c3591b041?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw0fHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Brume Matinale',
    artist: 'Hiro Sato',
    category: 'Sumi-e',
    likes: 1823,
    views: 10234,
    height: 'aspect-square'
  }
];

export function ArtShowcase() {
  return (
    <section className="py-20 px-6 bg-gradient-to-b from-background to-card/30">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-display italic mb-4">
            Galerie des créations
          </h2>
          <p className="text-lg text-muted-foreground font-accent italic">
            Une sélection des œuvres les plus remarquables de notre communauté
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {artworks.map((artwork, index) => (
            <ArtworkCard key={index} {...artwork} />
          ))}
        </div>

        <div className="text-center mt-12">
          <button className="px-8 py-4 border border-border bg-card/50 backdrop-blur text-foreground rounded-lg hover:bg-card hover:border-primary transition-all font-medium">
            Découvrir toutes les œuvres
          </button>
        </div>
      </div>
    </section>
  );
}

function ArtworkCard({
  image,
  title,
  artist,
  category,
  likes,
  views,
  height
}: {
  image: string;
  title: string;
  artist: string;
  category: string;
  likes: number;
  views: number;
  height: string;
}) {
  return (
    <div className="group relative overflow-hidden rounded-xl border border-border bg-card hover:border-primary/50 transition-all duration-300 cursor-pointer">
      <div className={`relative ${height} overflow-hidden`}>
        <ImageWithFallback
          src={image}
          alt={title}
          className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
        />

        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />

        <div className="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
          <button className="w-10 h-10 rounded-full bg-background/80 backdrop-blur-sm border border-border flex items-center justify-center hover:bg-primary hover:text-primary-foreground hover:border-primary transition-all">
            <Heart className="w-4 h-4" />
          </button>
          <button className="w-10 h-10 rounded-full bg-background/80 backdrop-blur-sm border border-border flex items-center justify-center hover:bg-primary hover:text-primary-foreground hover:border-primary transition-all">
            <Bookmark className="w-4 h-4" />
          </button>
        </div>

        <div className="absolute bottom-0 left-0 right-0 p-6 transform translate-y-2 group-hover:translate-y-0 transition-transform">
          <span className="inline-block px-3 py-1 bg-primary/20 border border-primary/30 rounded-full text-xs text-primary mb-3">
            {category}
          </span>
          <h3 className="text-xl font-display mb-1">{title}</h3>
          <p className="text-sm text-muted-foreground font-accent italic mb-4">
            par {artist}
          </p>

          <div className="flex items-center gap-6 text-sm text-muted-foreground">
            <span className="flex items-center gap-2">
              <Heart className="w-4 h-4" />
              {likes.toLocaleString()}
            </span>
            <span className="flex items-center gap-2">
              <Eye className="w-4 h-4" />
              {views.toLocaleString()}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
