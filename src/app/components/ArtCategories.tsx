import {
  Music,
  BookOpen,
  Film,
  Palette,
  Pen,
  Clapperboard,
} from "lucide-react";
import { ImageWithFallback } from "./ImageWithFallback";
import {
  getCategoryLabel,
  isCategoryMatch,
  type Artist,
  type Artwork,
  type Category,
  type CategorySlug,
  type Discussion,
  type SectionId,
} from "../data/community";
import { openCategoryPage } from "../lib/page-links";

const categoryIcons = {
  music: Music,
  "visual-art": Palette,
  manga: BookOpen,
  film: Film,
  literature: Pen,
  animation: Clapperboard,
};

interface ArtCategoriesProps {
  categories: Category[];
  artists: Artist[];
  artworks: Artwork[];
  discussions: Discussion[];
  selectedCategory: CategorySlug;
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function ArtCategories({
  categories,
  artists,
  artworks,
  discussions,
  selectedCategory,
}: ArtCategoriesProps) {
  return (
    <section id="categories" className="px-6 py-20 scroll-mt-28">
      <div className="mx-auto max-w-7xl">
        <div className="mb-16 text-center">
          <h2 className="mb-4 text-4xl font-display italic md:text-5xl">
            Explorez par univers
          </h2>
          <p className="text-lg text-muted-foreground font-accent italic">
            Sélectionnez un univers pour synchroniser les artistes, la galerie
            et le forum.
          </p>
          <p className="mt-3 text-sm text-primary">
            Filtre actuel : {getCategoryLabel(selectedCategory)}
          </p>
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
          {categories.map((category) => {
            const Icon = categoryIcons[category.slug];
            const artistCount = artists.filter(
              (item) => item.category === category.slug,
            ).length;
            const artworkCount = artworks.filter(
              (item) => item.category === category.slug,
            ).length;
            const discussionCount = discussions.filter(
              (item) => item.category === category.slug,
            ).length;
            const isActive = isCategoryMatch(selectedCategory, category.slug);

            return (
              <button
                key={category.slug}
                className={`group relative overflow-hidden rounded-xl border bg-card text-left transition-all duration-300 ${
                  isActive
                    ? "border-primary shadow-lg shadow-primary/10"
                    : "border-border hover:border-primary/50"
                }`}
                onClick={() => openCategoryPage(category.slug)}
              >
                <div className="absolute inset-0 opacity-30 transition-opacity group-hover:opacity-40">
                  <ImageWithFallback
                    src={category.image}
                    alt={category.title}
                    className="h-full w-full object-cover"
                  />
                </div>

                <div
                  className={`absolute inset-0 bg-gradient-to-br ${category.color}`}
                />

                <div className="relative flex min-h-[320px] flex-col justify-between p-6">
                  <div>
                    <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg border border-primary/30 bg-primary/20 transition-transform group-hover:scale-110">
                      <Icon className="h-6 w-6 text-primary" />
                    </div>
                    <h3 className="mb-2 text-2xl font-display">
                      {category.title}
                    </h3>
                    <p className="text-muted-foreground">
                      {category.description}
                    </p>
                  </div>

                  <div className="space-y-4">
                    <div className="flex flex-wrap gap-2 text-xs text-muted-foreground">
                      <span className="rounded-full border border-border bg-background/70 px-3 py-1">
                        {artistCount} artistes
                      </span>
                      <span className="rounded-full border border-border bg-background/70 px-3 py-1">
                        {artworkCount} œuvres
                      </span>
                      <span className="rounded-full border border-border bg-background/70 px-3 py-1">
                        {discussionCount} discussions
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-primary">
                      <span className="text-sm font-medium">
                        Ouvrir la page dédiée
                      </span>
                      <span className="text-xs uppercase tracking-[0.2em]">
                        {category.targetSectionId}
                      </span>
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </section>
  );
}
