import { MessageCircle, TrendingUp, Clock } from 'lucide-react';

const discussions = [
  {
    title: 'Techniques d\'encrage pour le manga moderne',
    author: 'Yuki Tanaka',
    category: 'Manga',
    replies: 127,
    time: 'Il y a 2h',
    trending: true
  },
  {
    title: 'Composition musicale : harmonie entre classique et électro',
    author: 'Sophie Martin',
    category: 'Musique',
    replies: 94,
    time: 'Il y a 5h',
    trending: true
  },
  {
    title: 'L\'influence de Vagabond sur le manga contemporain',
    author: 'Kenji Watanabe',
    category: 'Manga',
    replies: 203,
    time: 'Il y a 8h',
    trending: false
  },
  {
    title: 'Créer des atmosphères victoriennnes dans vos illustrations',
    author: 'Emma Clarke',
    category: 'Art',
    replies: 76,
    time: 'Il y a 12h',
    trending: false
  },
  {
    title: 'Comment auto-publier son premier court-métrage ?',
    author: 'Marco Rossi',
    category: 'Film',
    replies: 145,
    time: 'Hier',
    trending: true
  }
];

export function CommunityFeed() {
  return (
    <section className="py-20 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="flex items-end justify-between mb-12">
          <div>
            <h2 className="text-4xl md:text-5xl font-display italic mb-2">
              Le forum créatif
            </h2>
            <p className="text-muted-foreground font-accent italic">
              Échangez, apprenez et grandissez ensemble
            </p>
          </div>
          <button className="hidden md:block px-6 py-3 bg-primary text-primary-foreground rounded-lg hover:opacity-90 transition-opacity">
            Créer un sujet
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-4">
            {discussions.map((discussion, index) => (
              <DiscussionCard key={index} {...discussion} />
            ))}
          </div>

          <div className="space-y-6">
            <div className="border border-border rounded-xl p-6 bg-card">
              <h3 className="font-display text-xl mb-4">Tendances du jour</h3>
              <div className="space-y-3">
                <TrendTag tag="#MangaIndé" count="2.4k" />
                <TrendTag tag="#BeethovenModerne" count="1.8k" />
                <TrendTag tag="#StreetArtPoetry" count="1.2k" />
                <TrendTag tag="#CinémaExpérimental" count="987" />
                <TrendTag tag="#IllustrationVictorian" count="765" />
              </div>
            </div>

            <div className="border border-border rounded-xl p-6 bg-card">
              <h3 className="font-display text-xl mb-4">Événements à venir</h3>
              <div className="space-y-4">
                <EventCard
                  title="Webinaire : L'art du storytelling"
                  date="15 Juin"
                />
                <EventCard
                  title="Concours de composition musicale"
                  date="22 Juin"
                />
                <EventCard
                  title="Expo virtuelle : Manga & BD"
                  date="1 Juillet"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function DiscussionCard({
  title,
  author,
  category,
  replies,
  time,
  trending
}: {
  title: string;
  author: string;
  category: string;
  replies: number;
  time: string;
  trending: boolean;
}) {
  return (
    <div className="group border border-border rounded-xl p-6 bg-card hover:border-primary/50 hover:bg-card/80 transition-all cursor-pointer">
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1">
          <div className="flex items-center gap-3 mb-2">
            <span className="px-3 py-1 bg-secondary/20 border border-secondary/30 rounded-full text-xs text-secondary-foreground">
              {category}
            </span>
            {trending && (
              <span className="flex items-center gap-1 text-xs text-primary">
                <TrendingUp className="w-3 h-3" />
                Tendance
              </span>
            )}
          </div>

          <h3 className="text-lg font-medium mb-2 group-hover:text-primary transition-colors">
            {title}
          </h3>

          <div className="flex items-center gap-4 text-sm text-muted-foreground">
            <span>Par {author}</span>
            <span className="flex items-center gap-1">
              <Clock className="w-3 h-3" />
              {time}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2 text-muted-foreground">
          <MessageCircle className="w-5 h-5" />
          <span className="font-medium">{replies}</span>
        </div>
      </div>
    </div>
  );
}

function TrendTag({ tag, count }: { tag: string; count: string }) {
  return (
    <button className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-muted transition-colors text-left">
      <span className="text-primary font-medium">{tag}</span>
      <span className="text-sm text-muted-foreground">{count} posts</span>
    </button>
  );
}

function EventCard({ title, date }: { title: string; date: string }) {
  return (
    <div className="p-3 rounded-lg border border-border hover:border-primary/50 transition-colors cursor-pointer">
      <p className="text-sm font-medium mb-1">{title}</p>
      <p className="text-xs text-muted-foreground">{date}</p>
    </div>
  );
}
