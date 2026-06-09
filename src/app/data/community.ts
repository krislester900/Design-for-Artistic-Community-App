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

export const artists: Artist[] = [];

export const artworks: Artwork[] = [];

export const discussions: Discussion[] = [];

export const trends: Trend[] = [];

export const events: EventItem[] = [];

export const communityStats: CommunityStat[] = [
  { number: "0", label: "Artistes actifs" },
  { number: "0", label: "Œuvres publiées" },
  { number: "0", label: "Discussions" },
  { number: "0", label: "Satisfaction" },
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
