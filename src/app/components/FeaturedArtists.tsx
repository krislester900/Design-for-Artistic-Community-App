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
      className="bg-gradient-to-b from-background via-card/10 to-background px-6 py-20 scroll-mt-28"
    >
      <div className="mx-auto max-w-7xl">
        <div className="mb-12 flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="mb-4 text-xs font-semibold uppercase tracking-[0.32em] text-secondary">
              Creators wall
            </p>
            <h2 className="street-title mb-2 text-4xl md:text-5xl">
              Artistes en lumière
            </h2>
            <p className="street-copy">
              {selectedCategory === "all"
                ? "Découvrez les créateurs qui façonnent notre communauté."
                : `Créateurs mis en avant pour l'univers ${getCategoryLabel(selectedCategory).toLowerCase()}.`}
            </p>
          </div>
          <button
            className="rounded-xl border border-border bg-card/60 px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] transition-colors hover:border-primary hover:text-primary"
            onClick={() => onNavigate("showcase", selectedCategory)}
          >
            Voir les œuvres liées
          </button>
        </div>

        {filteredArtists.length > 0 ? (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-4">
            {filteredArtists.map((artist) => (
              <ArtistCard
                key={artist.name}
                {...artist}
                onNavigate={onNavigate}
              />
            ))}
          </div>
        ) : (
          <EmptyStateCard
            title="Aucun artiste publié pour le moment"
            description="Les profils apparaîtront ici dès qu'un premier créateur sera ajouté à la plateforme."
          />
        )}
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
      className="group relative overflow-hidden rounded-[1.5rem] border border-border bg-card text-left transition-all duration-300 hover:-translate-y-1 hover:border-primary/55"
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
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/65 to-transparent" />
        <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(40,216,255,0.06),transparent_30%,rgba(255,106,26,0.18))]" />
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-transparent via-accent to-primary" />

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
          <span className="street-chip mb-3 border-primary/30 text-primary">
            {role}
          </span>
          <h3 className="street-title mb-1 text-2xl">{name}</h3>
          <p className="street-copy mb-4 text-sm">
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
