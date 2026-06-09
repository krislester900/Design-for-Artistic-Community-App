import { ImageWithFallback } from "./ImageWithFallback";
import { Heart, Eye, Bookmark } from "lucide-react";
import {
  getCategoryLabel,
  isCategoryMatch,
  type Artwork,
  type CategorySlug,
  type SectionId,
} from "../data/community";

interface ArtShowcaseProps {
  artworks: Artwork[];
  selectedCategory: CategorySlug;
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function ArtShowcase({
  artworks,
  selectedCategory,
  onNavigate,
}: ArtShowcaseProps) {
  const filteredArtworks = artworks.filter((artwork) =>
    isCategoryMatch(selectedCategory, artwork.category),
  );

  return (
    <section
      id="showcase"
      className="bg-gradient-to-b from-background to-card/20 px-6 py-20 scroll-mt-28"
    >
      <div className="mx-auto max-w-7xl">
        <div className="mb-16 text-center">
          <p className="mb-4 text-xs font-semibold uppercase tracking-[0.32em] text-accent">
            Gallery drop
          </p>
          <h2 className="street-title mb-4 text-4xl md:text-5xl">
            Galerie des créations
          </h2>
          <p className="street-copy text-lg">
            {selectedCategory === "all"
              ? "Une sélection des œuvres les plus remarquables de notre communauté."
              : `Œuvres actuellement connectées à l'univers ${getCategoryLabel(selectedCategory).toLowerCase()}.`}
          </p>
        </div>

        {filteredArtworks.length > 0 ? (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {filteredArtworks.map((artwork) => (
              <ArtworkCard
                key={`${artwork.title}-${artwork.artist}`}
                {...artwork}
                onNavigate={onNavigate}
              />
            ))}
          </div>
        ) : (
          <EmptyStateCard
            title="Aucune œuvre publiée pour le moment"
            description="La galerie se remplira automatiquement dès qu'une première création sera mise en ligne."
          />
        )}

        <div className="mt-12 text-center">
          <button
            className="rounded-xl border border-border bg-card/60 px-8 py-4 text-xs font-semibold uppercase tracking-[0.2em] text-foreground backdrop-blur transition-all hover:border-primary hover:bg-card"
            onClick={() => onNavigate("forum", selectedCategory)}
          >
            Ouvrir les discussions liées
          </button>
        </div>
      </div>
    </section>
  );
}

function EmptyStateCard({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="street-panel rounded-2xl border-dashed p-10 text-center">
      <h3 className="street-title mb-2 text-2xl">{title}</h3>
      <p className="mx-auto max-w-2xl text-muted-foreground">{description}</p>
    </div>
  );
}

function ArtworkCard({
  image,
  title,
  artist,
  category,
  medium,
  likes,
  views,
  height,
  onNavigate,
}: Artwork & {
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}) {
  const handleOpen = () => onNavigate("forum", category);

  return (
    <div
      className="group relative cursor-pointer overflow-hidden rounded-[1.5rem] border border-border bg-card text-left transition-all duration-300 hover:-translate-y-1 hover:border-primary/60"
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
      <div className={`relative overflow-hidden ${height}`}>
        <ImageWithFallback
          src={image}
          alt={title}
          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
        />

        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/60 to-transparent opacity-100" />
        <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(9,9,13,0.08),transparent_35%,rgba(255,106,26,0.18))]" />
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-transparent via-primary to-secondary" />

        <div className="absolute right-4 top-4 flex gap-2 opacity-0 transition-opacity group-hover:opacity-100">
          <button
            className="flex h-10 w-10 items-center justify-center rounded-full border border-border bg-background/80 backdrop-blur-sm transition-all hover:border-primary hover:bg-primary hover:text-primary-foreground"
            onClick={(event) => {
              event.stopPropagation();
              onNavigate("join", category);
            }}
          >
            <Heart className="h-4 w-4" />
          </button>
          <button
            className="flex h-10 w-10 items-center justify-center rounded-full border border-border bg-background/80 backdrop-blur-sm transition-all hover:border-primary hover:bg-primary hover:text-primary-foreground"
            onClick={(event) => {
              event.stopPropagation();
              onNavigate("artists", category);
            }}
          >
            <Bookmark className="h-4 w-4" />
          </button>
        </div>

        <div className="absolute bottom-0 left-0 right-0 translate-y-2 p-6 transition-transform group-hover:translate-y-0">
          <span className="street-chip mb-3 border-primary/30 text-primary">
            {medium}
          </span>
          <h3 className="street-title mb-1 text-2xl">{title}</h3>
          <p className="street-copy mb-4 text-sm">
            par {artist}
          </p>

          <div className="flex items-center gap-6 text-sm text-muted-foreground">
            <span className="flex items-center gap-2">
              <Heart className="h-4 w-4" />
              {likes.toLocaleString()}
            </span>
            <span className="flex items-center gap-2">
              <Eye className="h-4 w-4" />
              {views.toLocaleString()}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
