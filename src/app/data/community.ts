export type CategorySlug =
  | "all"
  | "music"
  | "visual-art"
  | "manga"
  | "film"
  | "literature"
  | "animation";

export type SectionId =
  | "hero"
  | "categories"
  | "artists"
  | "showcase"
  | "forum"
  | "join";

export interface Category {
  slug: Exclude<CategorySlug, "all">;
  title: string;
  shortLabel: string;
  description: string;
  image: string;
  color: string;
  targetSectionId: Exclude<SectionId, "hero" | "categories" | "join">;
}

export interface Artist {
  name: string;
  category: Exclude<CategorySlug, "all">;
  role: string;
  image: string;
  featuredWork: string;
  likes: number;
}

export interface Artwork {
  image: string;
  title: string;
  artist: string;
  category: Exclude<CategorySlug, "all">;
  medium: string;
  likes: number;
  views: number;
  height: string;
}

export interface Discussion {
  title: string;
  author: string;
  category: Exclude<CategorySlug, "all">;
  replies: number;
  time: string;
  trending: boolean;
}

export interface Trend {
  tag: string;
  count: string;
  category: Exclude<CategorySlug, "all">;
}

export interface EventItem {
  title: string;
  date: string;
  category: Exclude<CategorySlug, "all">;
}

export interface CommunityStat {
  number: string;
  label: string;
}

export interface FooterLinkItem {
  text: string;
  sectionId: SectionId;
  category?: CategorySlug;
}

export interface FooterSection {
  title: string;
  links: FooterLinkItem[];
}

export interface CommunityData {
  categories: Category[];
  artists: Artist[];
  artworks: Artwork[];
  discussions: Discussion[];
  trends: Trend[];
  events: EventItem[];
  communityStats: CommunityStat[];
}

export type CommunityDataSource = "mock" | "supabase";

export const categoryLabels: Record<CategorySlug, string> = {
  all: "Tous les univers",
  music: "Musique",
  "visual-art": "Art visuel",
  manga: "Manga & BD",
  film: "Films indépendants",
  literature: "Littérature",
  animation: "Animation",
};

export const navigationItems: Array<{
  label: string;
  sectionId: SectionId;
  category?: CategorySlug;
}> = [
  { label: "Accueil", sectionId: "hero" },
  { label: "Univers", sectionId: "categories" },
  { label: "Artistes", sectionId: "artists" },
  { label: "Galerie", sectionId: "showcase" },
  { label: "Forum", sectionId: "forum" },
  { label: "Rejoindre", sectionId: "join" },
];

export const footerSections: FooterSection[] = [
  {
    title: "Explorer",
    links: [
      { text: "Accueil", sectionId: "hero" },
      { text: "Univers", sectionId: "categories" },
      { text: "Galerie", sectionId: "showcase" },
    ],
  },
  {
    title: "Communauté",
    links: [
      { text: "Artistes", sectionId: "artists" },
      { text: "Forum", sectionId: "forum" },
      { text: "Créer un compte", sectionId: "join" },
    ],
  },
  {
    title: "Univers",
    links: [
      { text: "Tous les univers", sectionId: "categories", category: "all" },
      { text: "Musique", sectionId: "showcase", category: "music" },
      { text: "Manga & BD", sectionId: "showcase", category: "manga" },
      { text: "Films", sectionId: "showcase", category: "film" },
    ],
  },
];

export const categories: Category[] = [
  {
    slug: "music",
    title: "Musique",
    shortLabel: "Musique",
    description: "Compositions, EP, bandes-son et performances live.",
    image:
      "https://images.unsplash.com/photo-1541961017774-22349e4a1262?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwzfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080",
    color: "from-primary/20 to-primary/5",
    targetSectionId: "showcase",
  },
  {
    slug: "visual-art",
    title: "Art Visuel",
    shortLabel: "Art",
    description: "Illustration, peinture, photo et créations graphiques.",
    image:
      "https://images.unsplash.com/photo-1618331833071-ce81bd50d300?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080",
    color: "from-secondary/20 to-secondary/5",
    targetSectionId: "showcase",
  },
  {
    slug: "manga",
    title: "Manga & BD",
    shortLabel: "Manga",
    description: "Planches, chapitres, concept art et univers narratifs.",
    image:
      "https://images.unsplash.com/photo-1763732397864-5b860bb298b0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080",
    color: "from-accent/20 to-accent/5",
    targetSectionId: "artists",
  },
  {
    slug: "film",
    title: "Films indépendants",
    shortLabel: "Films",
    description: "Courts-métrages, teasers, scénarios et making-of.",
    image:
      "https://images.unsplash.com/photo-1618331835717-801e976710b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw0fHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080",
    color: "from-chart-4/20 to-chart-4/5",
    targetSectionId: "showcase",
  },
  {
    slug: "literature",
    title: "Littérature",
    shortLabel: "Littérature",
    description: "Poésie, nouvelles, manifestes et récits illustrés.",
    image:
      "https://images.unsplash.com/photo-1533208087231-c3618eab623c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw1fHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080",
    color: "from-chart-5/20 to-chart-5/5",
    targetSectionId: "forum",
  },
  {
    slug: "animation",
    title: "Animation",
    shortLabel: "Animation",
    description:
      "Motion design, animation 2D/3D et expérimentations visuelles.",
    image:
      "https://images.unsplash.com/photo-1779864535439-292f58c6c6a4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw1fHxzdHJlZXQlMjBhcnQlMjBncmFmZml0aSUyMHZpY3RvcmlhbiUyMGFyY2hpdGVjdHVyZXxlbnwxfHx8fDE3ODA5OTYzMTB8MA&ixlib=rb-4.1.0&q=80&w=1080",
    color: "from-primary/20 to-secondary/5",
    targetSectionId: "showcase",
  },
];

export const artists: Artist[] = [
  {
    name: "Akira Sato",
    category: "manga",
    role: "Mangaka",
    image:
      "https://images.unsplash.com/photo-1777645948844-24859533196e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwzfHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080",
    featuredWork: "Les Ombres du Crépuscule",
    likes: 2847,
  },
  {
    name: "Maya Dubois",
    category: "music",
    role: "Compositrice",
    image:
      "https://images.unsplash.com/photo-1770739520456-5fb5df8b25fc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwzfHxzdHJlZXQlMjBhcnQlMjBncmFmZml0aSUyMHZpY3RvcmlhbiUyMGFyY2hpdGVjdHVyZXxlbnwxfHx8fDE3ODA5OTYzMTB8MA&ixlib=rb-4.1.0&q=80&w=1080",
    featuredWork: "Symphonie Urbaine Vol.3",
    likes: 3921,
  },
  {
    name: "Lucas Stone",
    category: "film",
    role: "Cinéaste",
    image:
      "https://images.unsplash.com/photo-1764023874407-acac56960791?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxzdHJlZXQlMjBhcnQlMjBncmFmZml0aSUyMHZpY3RvcmlhbiUyMGFyY2hpdGVjdHVyZXxlbnwxfHx8fDE3ODA5OTYzMTB8MA&ixlib=rb-4.1.0&q=80&w=1080",
    featuredWork: "Le Dernier Métro",
    likes: 1654,
  },
  {
    name: "Amélie Laurent",
    category: "visual-art",
    role: "Illustratrice",
    image:
      "https://images.unsplash.com/photo-1762860498297-4b6c3591b041?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw0fHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080",
    featuredWork: "Jardins de Soie",
    likes: 4182,
  },
  {
    name: "Nora Bellier",
    category: "literature",
    role: "Autrice",
    image:
      "https://images.unsplash.com/photo-1494790108377-be9c29b29330?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080",
    featuredWork: "Le Bruit des Pages",
    likes: 1388,
  },
  {
    name: "Eli Moreno",
    category: "animation",
    role: "Motion designer",
    image:
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080",
    featuredWork: "Fragments en Mouvement",
    likes: 2217,
  },
];

export const artworks: Artwork[] = [
  {
    image:
      "https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080",
    title: "Émotions Abstraites",
    artist: "Sophie Moreau",
    category: "visual-art",
    medium: "Peinture",
    likes: 1247,
    views: 8934,
    height: "aspect-square",
  },
  {
    image:
      "https://images.unsplash.com/photo-1618331833071-ce81bd50d300?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080",
    title: "Rêves Urbains",
    artist: "Marc Dubois",
    category: "animation",
    medium: "Motion design",
    likes: 892,
    views: 5621,
    height: "aspect-[3/4]",
  },
  {
    image:
      "https://images.unsplash.com/photo-1763732397864-5b860bb298b0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwyfHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080",
    title: "Chroniques Vol. 1",
    artist: "Yuki Tanaka",
    category: "manga",
    medium: "Manga",
    likes: 2103,
    views: 12450,
    height: "aspect-[3/4]",
  },
  {
    image:
      "https://images.unsplash.com/photo-1777645948844-24859533196e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwzfHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080",
    title: "Masque Ancestral",
    artist: "Kaito Nakamura",
    category: "visual-art",
    medium: "Encre",
    likes: 1567,
    views: 9234,
    height: "aspect-square",
  },
  {
    image:
      "https://images.unsplash.com/photo-1618331835717-801e976710b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw0fHxhYnN0cmFjdCUyMGFydCUyMHBhaW50aW5nJTIwdGV4dHVyZXN8ZW58MXx8fHwxNzgwOTk2MzExfDA&ixlib=rb-4.1.0&q=80&w=1080",
    title: "Le Dernier Plan",
    artist: "Lucas Stone",
    category: "film",
    medium: "Court-métrage",
    likes: 734,
    views: 4521,
    height: "aspect-[4/3]",
  },
  {
    image:
      "https://images.unsplash.com/photo-1762860498297-4b6c3591b041?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw0fHxtYW5nYSUyMGFydCUyMGphcGFuZXNlJTIwaW5rfGVufDF8fHx8MTc4MDk5NjMxMXww&ixlib=rb-4.1.0&q=80&w=1080",
    title: "Brume Matinale",
    artist: "Hiro Sato",
    category: "literature",
    medium: "Poème illustré",
    likes: 1823,
    views: 10234,
    height: "aspect-square",
  },
  {
    image:
      "https://images.unsplash.com/photo-1511379938547-c1f69419868d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080",
    title: "Nocturne Analogique",
    artist: "Maya Dubois",
    category: "music",
    medium: "EP",
    likes: 2671,
    views: 14201,
    height: "aspect-[4/3]",
  },
];

export const discussions: Discussion[] = [
  {
    title: "Techniques d'encrage pour le manga moderne",
    author: "Yuki Tanaka",
    category: "manga",
    replies: 127,
    time: "Il y a 2h",
    trending: true,
  },
  {
    title: "Composer entre classique et électro sans perdre son identité",
    author: "Sophie Martin",
    category: "music",
    replies: 94,
    time: "Il y a 5h",
    trending: true,
  },
  {
    title: "Créer des atmosphères victoriennes dans vos illustrations",
    author: "Emma Clarke",
    category: "visual-art",
    replies: 76,
    time: "Il y a 12h",
    trending: false,
  },
  {
    title: "Comment auto-publier son premier court-métrage ?",
    author: "Marco Rossi",
    category: "film",
    replies: 145,
    time: "Hier",
    trending: true,
  },
  {
    title: "Donner une voix visuelle à un texte poétique",
    author: "Nora Bellier",
    category: "literature",
    replies: 58,
    time: "Hier",
    trending: false,
  },
  {
    title: "Workflow 2D/3D pour une boucle animée immersive",
    author: "Eli Moreno",
    category: "animation",
    replies: 83,
    time: "Il y a 3h",
    trending: true,
  },
];

export const trends: Trend[] = [
  { tag: "#MangaIndé", count: "2.4k", category: "manga" },
  { tag: "#BeatsNocturnes", count: "1.8k", category: "music" },
  { tag: "#IllustrationVictorian", count: "1.2k", category: "visual-art" },
  { tag: "#CinemaExperimental", count: "987", category: "film" },
  { tag: "#PoesieVisuelle", count: "765", category: "literature" },
  { tag: "#LoopAnimation", count: "652", category: "animation" },
];

export const events: EventItem[] = [
  {
    title: "Webinaire : l'art du storytelling visuel",
    date: "15 Juin",
    category: "visual-art",
  },
  {
    title: "Concours de composition musicale",
    date: "22 Juin",
    category: "music",
  },
  {
    title: "Projection : courts métrages de la communauté",
    date: "1 Juillet",
    category: "film",
  },
  {
    title: "Salon des auteurs indépendants",
    date: "8 Juillet",
    category: "literature",
  },
];

export const communityStats: CommunityStat[] = [
  { number: "12K+", label: "Artistes actifs" },
  { number: "45K+", label: "Œuvres publiées" },
  { number: "2M+", label: "Discussions" },
  { number: "98%", label: "Satisfaction" },
];

export const mockCommunityData: CommunityData = {
  categories,
  artists,
  artworks,
  discussions,
  trends,
  events,
  communityStats,
};

export function isCategoryMatch(
  selectedCategory: CategorySlug,
  itemCategory: Exclude<CategorySlug, "all">,
) {
  return selectedCategory === "all" || selectedCategory === itemCategory;
}

export function getCategoryLabel(category: CategorySlug) {
  return categoryLabels[category];
}

export function getCategoryBySlug(category: Exclude<CategorySlug, "all">) {
  return categories.find((item) => item.slug === category);
}
