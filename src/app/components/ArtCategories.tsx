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
    <section
      id="categories"
      className="border-t border-border/70 px-6 py-20 scroll-mt-28"
    >
      <div className="mx-auto max-w-7xl">
        <div className="mb-16 text-center">
          <p className="mb-4 text-xs font-semibold uppercase tracking-[0.32em] text-primary">
            Univers connectes
          </p>
          <h2 className="street-title mb-4 text-4xl md:text-5xl">
            Explorez par univers
          </h2>
          <p className="street-copy text-lg">
            Sélectionnez un univers pour synchroniser les artistes, la galerie
            et le forum.
          </p>
          <p className="mt-3 text-sm uppercase tracking-[0.16em] text-primary">
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
                className={`group relative overflow-hidden rounded-[1.5rem] border bg-card text-left transition-all duration-300 ${
                  isActive
                    ? "border-primary shadow-[0_20px_46px_rgba(255,106,26,0.16)]"
                    : "border-border hover:-translate-y-1 hover:border-primary/60"
                }`}
                onClick={() => openCategoryPage(category.slug)}
              >
                <div className="absolute inset-0 opacity-25 transition-opacity group-hover:opacity-40">
                  <ImageWithFallback
                    src={category.image}
                    alt={category.title}
                    className="h-full w-full object-cover"
                  />
                </div>

                <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(9,9,13,0.25),rgba(9,9,13,0.8))]" />
                <div
                  className={`absolute inset-0 bg-gradient-to-br ${category.color}`}
                />
                <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-transparent via-primary to-accent" />

                <div className="relative flex min-h-[320px] flex-col justify-between p-6">
                  <div>
                    <div className="mb-4 flex h-12 w-12 -rotate-3 items-center justify-center rounded-2xl border border-primary/35 bg-background/70 transition-transform group-hover:scale-110 group-hover:rotate-0">
                      <Icon className="h-6 w-6 text-primary" />
                    </div>
                    <h3 className="street-title mb-2 text-2xl">
                      {category.title}
                    </h3>
                    <p className="street-copy text-sm leading-7 md:text-base">
                      {category.description}
                    </p>
                  </div>

                  <div className="space-y-4">
                    <div className="flex flex-wrap gap-2 text-xs text-muted-foreground">
                      <span className="street-chip">
                        {artistCount} artistes
                      </span>
                      <span className="street-chip">
                        {artworkCount} œuvres
                      </span>
                      <span className="street-chip">
                        {discussionCount} discussions
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-primary">
                      <span className="text-sm font-semibold uppercase tracking-[0.16em]">
                        Ouvrir la page dédiée
                      </span>
                      <span className="text-xs uppercase tracking-[0.24em] text-muted-foreground">
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
