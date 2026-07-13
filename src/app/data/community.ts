export type CategorySlug =
  | "all"
  | "music"
  | "visual-art"
  | "manga"
  | "film"
  | "literature"
  | "animation"
  | "games";

export type SectionId =
  | "hero"
  | "categories"
  | "artists"
  | "showcase"
  | "forum"
  | "chat"
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
  games: "Jeux",
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
  { label: "Chat", sectionId: "chat" },
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
      { text: "Chat", sectionId: "chat" },
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
    description: "Motion design, animation 2D/3D et expérimentations visuelles.",
    image:
      "https://images.unsplash.com/photo-1779864535439-292f58c6c6a4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHw1fHxzdHJlZXQlMjBhcnQlMjBncmFmZml0aSUyMHZpY3RvcmlhbiUyMGFyY2hpdGVjdHVyZXxlbnwxfHx8fDE3ODA5OTYzMTB8MA&ixlib=rb-4.1.0&q=80&w=1080",
    color: "from-primary/20 to-secondary/5",
    targetSectionId: "showcase",
  },
];

export const artists: Artist[] = [
  {
    name: "Naya Pulse",
    category: "music",
    role: "Beatmaker & performeuse",
    image: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&h=200&fit=crop&crop=faces",
    featuredWork: "Pulse Nocturne",
    likes: 1280,
  },
  {
    name: "Kiro Ink",
    category: "manga",
    role: "Mangaka indépendant",
    image: "https://images.unsplash.com/photo-1560972550-aba3456b5564?w=200&h=200&fit=crop&crop=faces",
    featuredWork: "Fragments de Néon",
    likes: 980,
  },
  {
    name: "Mila Chrom",
    category: "visual-art",
    role: "Illustratrice digitale",
    image: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&crop=faces",
    featuredWork: "Portraits Urbains",
    likes: 1540,
  },
  {
    name: "Ari Vox",
    category: "literature",
    role: "Poète spoken word",
    image: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=faces",
    featuredWork: "Minuit sur Béton",
    likes: 860,
  },
  {
    name: "Soren Frame",
    category: "film",
    role: "Réalisateur de courts-métrages",
    image: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=faces",
    featuredWork: "Dernière Station",
    likes: 1110,
  },
  {
    name: "Luma Motion",
    category: "animation",
    role: "Motion designer 2D/3D",
    image: "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200&h=200&fit=crop&crop=faces",
    featuredWork: "Echo Loops",
    likes: 1205,
  },
];

export const artworks: Artwork[] = [
  {
    image: "https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=400&h=400&fit=crop",
    title: "Pulse Nocturne",
    artist: "Naya Pulse",
    category: "music",
    medium: "EP",
    likes: 420,
    views: 5400,
    height: "medium",
  },
  {
    image: "https://images.unsplash.com/photo-1549490349-8643362247b5?w=400&h=400&fit=crop",
    title: "Portraits Urbains",
    artist: "Mila Chrom",
    category: "visual-art",
    medium: "Illustration",
    likes: 610,
    views: 7200,
    height: "large",
  },
  {
    image: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400&h=400&fit=crop",
    title: "Fragments de Néon",
    artist: "Kiro Ink",
    category: "manga",
    medium: "Chapitre pilote",
    likes: 390,
    views: 4600,
    height: "medium",
  },
  {
    image: "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=400&h=400&fit=crop",
    title: "Dernière Station",
    artist: "Soren Frame",
    category: "film",
    medium: "Court-métrage",
    likes: 515,
    views: 6800,
    height: "large",
  },
  {
    image: "https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400&h=400&fit=crop",
    title: "Minuit sur Béton",
    artist: "Ari Vox",
    category: "literature",
    medium: "Poème visuel",
    likes: 275,
    views: 3100,
    height: "small",
  },
  {
    image: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&h=400&fit=crop",
    title: "Echo Loops",
    artist: "Luma Motion",
    category: "animation",
    medium: "Motion design",
    likes: 440,
    views: 5900,
    height: "medium",
  },
];

export const discussions: Discussion[] = [
  {
    title: "Vos références visuelles du moment ?",
    author: "Mila Chrom",
    category: "visual-art",
    replies: 24,
    time: "Il y a 2 h",
    trending: true,
  },
  {
    title: "Comment publier un premier chapitre efficacement ?",
    author: "Kiro Ink",
    category: "manga",
    replies: 18,
    time: "Il y a 4 h",
    trending: true,
  },
  {
    title: "Plugins audio préférés pour des textures lo-fi",
    author: "Naya Pulse",
    category: "music",
    replies: 31,
    time: "Aujourd'hui",
    trending: false,
  },
  {
    title: "Workflow rapide pour teaser un court-métrage",
    author: "Soren Frame",
    category: "film",
    replies: 12,
    time: "Hier",
    trending: false,
  },
  {
    title: "Texte court ou texte long sur mobile ?",
    author: "Ari Vox",
    category: "literature",
    replies: 16,
    time: "Hier",
    trending: false,
  },
];

export const trends: Trend[] = [
  { tag: "#neonportrait", count: "2.1k posts", category: "visual-art" },
  { tag: "#beatmaking", count: "1.6k posts", category: "music" },
  { tag: "#mangapanel", count: "980 posts", category: "manga" },
  { tag: "#microfiction", count: "640 posts", category: "literature" },
];

export const events: EventItem[] = [
  { title: "Session live croquis & critique", date: "18 juin", category: "visual-art" },
  { title: "Écoute collective des prods", date: "20 juin", category: "music" },
  { title: "Lecture ouverte spoken word", date: "22 juin", category: "literature" },
  { title: "Projection courts indépendants", date: "28 juin", category: "film" },
];

export const communityStats: CommunityStat[] = [
  { number: "2.4k", label: "Artistes actifs" },
  { number: "8.9k", label: "Œuvres publiées" },
  { number: "1.2k", label: "Discussions" },
  { number: "96%", label: "Satisfaction" },
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
