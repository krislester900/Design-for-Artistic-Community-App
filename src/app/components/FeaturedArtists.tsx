import { ImageWithFallback } from "./ImageWithFallback";
import { Play, Heart, Share2 } from "lucide-react";
import {
  getCategoryLabel,
  isCategoryMatch,
  type Artist,
  type CategorySlug,
  type SectionId,
} from "../data/community";

interface FeaturedArtistsProps {
  artists: Artist[];
  selectedCategory: CategorySlug;
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function FeaturedArtists({
  artists,
  selectedCategory,
  onNavigate,
}: FeaturedArtistsProps) {
  const filteredArtists = artists.filter((artist) =>
    isCategoryMatch(selectedCategory, artist.category),
  );

  return (
    <section
      id="artists"
      className="bg-gradient-to-b from-background via-card/20 to-background px-6 py-20 scroll-mt-28"
    >
      <div className="mx-auto max-w-7xl">
        <div className="mb-12 flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
          <div>
            <h2 className="mb-2 text-4xl font-display italic md:text-5xl">
              Artistes en lumière
            </h2>
            <p className="font-accent italic text-muted-foreground">
              {selectedCategory === "all"
                ? "Découvrez les créateurs qui façonnent notre communauté."
                : `Créateurs mis en avant pour l'univers ${getCategoryLabel(selectedCategory).toLowerCase()}.`}
            </p>
          </div>
          <button
            className="rounded-lg border border-border px-6 py-3 transition-colors hover:border-primary hover:text-primary"
            onClick={() => onNavigate("showcase", selectedCategory)}
          >
            Voir les œuvres liées
          </button>
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-4">
          {filteredArtists.map((artist) => (
            <ArtistCard key={artist.name} {...artist} onNavigate={onNavigate} />
          ))}
        </div>
      </div>
    </section>
  );
}

function ArtistCard({
  name,
  category,
  role,
  image,
  featuredWork,
  likes,
  onNavigate,
}: Artist & {
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}) {
  const handleOpen = () => onNavigate("showcase", category);

  return (
    <div
      className="group relative overflow-hidden rounded-xl border border-border bg-card text-left transition-all duration-300 hover:border-primary/50"
      role="button"
      tabIndex={0}
      onClick={handleOpen}
      onKeyDown={(event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          handleOpen();
        }
      }}
    >
      <div className="relative aspect-[3/4] overflow-hidden">
        <ImageWithFallback
          src={image}
          alt={name}
          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/60 to-transparent" />

        <button
          className="absolute right-4 top-4 flex h-10 w-10 items-center justify-center rounded-full border border-border bg-background/80 opacity-0 backdrop-blur-sm transition-opacity hover:border-primary hover:bg-primary hover:text-primary-foreground group-hover:opacity-100"
          onClick={(event) => {
            event.stopPropagation();
            onNavigate("showcase", category);
          }}
        >
          <Play className="ml-0.5 h-4 w-4" />
        </button>

        <div className="absolute bottom-0 left-0 right-0 p-6">
          <span className="mb-3 inline-block rounded-full border border-primary/30 bg-primary/20 px-3 py-1 text-xs text-primary">
            {role}
          </span>
          <h3 className="mb-1 text-xl font-display">{name}</h3>
          <p className="mb-4 text-sm font-accent italic text-muted-foreground">
            {featuredWork}
          </p>

          <div className="flex items-center gap-4">
            <button
              className="flex items-center gap-2 text-sm text-muted-foreground transition-colors hover:text-primary"
              onClick={(event) => {
                event.stopPropagation();
                onNavigate("join", category);
              }}
            >
              <Heart className="h-4 w-4" />
              <span>{likes.toLocaleString()}</span>
            </button>
            <button
              className="flex items-center gap-2 text-sm text-muted-foreground transition-colors hover:text-primary"
              onClick={(event) => {
                event.stopPropagation();
                onNavigate("forum", category);
              }}
            >
              <Share2 className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
