import {
  BookOpen,
  Clapperboard,
  Database,
  ExternalLink,
  Film,
  Home,
  Layers3,
  MessageCircle,
  Music4,
  Pen,
  Sparkles,
} from "lucide-react";
import { ArtisticPattern } from "../components/ArtisticPattern";
import { ImageWithFallback } from "../components/ImageWithFallback";
import { useCommunityData } from "../hooks/useCommunityData";
import {
  categoryLabels,
  getCategoryLabel,
  type Artist,
  type Artwork,
  type Discussion,
  type EventItem,
  type Trend,
} from "../data/community";
import {
  getStaticPagePath,
  staticPagePaths,
  type StaticPageId,
} from "../lib/page-links";

const databaseHeroImage =
  "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1400";
const communityHeroImage =
  "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1400";

type MultiPageAppProps = {
  page: string;
};

function isStaticPageId(value: string): value is StaticPageId {
  return value in staticPagePaths;
}

export function MultiPageApp({ page }: MultiPageAppProps) {
  if (!isStaticPageId(page)) {
    return null;
  }

  const { data, source, isLoading } = useCommunityData();
  const category = data.categories.find((item) => item.slug === page);
  const isCommunityPage = page === "community";
  const isDatabasePage = page === "database";

  const pageLinks = [
    {
      id: "home" as const,
      label: "Accueil",
      icon: <Home className="h-4 w-4" />,
    },
    {
      id: "music" as const,
      label: "Musique",
      icon: <Music4 className="h-4 w-4" />,
    },
    {
      id: "visual-art" as const,
      label: "Art visuel",
      icon: <Layers3 className="h-4 w-4" />,
    },
    {
      id: "manga" as const,
      label: "Manga",
      icon: <BookOpen className="h-4 w-4" />,
    },
    { id: "film" as const, label: "Films", icon: <Film className="h-4 w-4" /> },
    {
      id: "literature" as const,
      label: "Littérature",
      icon: <Pen className="h-4 w-4" />,
    },
    {
      id: "animation" as const,
      label: "Animation",
      icon: <Clapperboard className="h-4 w-4" />,
    },
    {
      id: "community" as const,
      label: "Communauté",
      icon: <MessageCircle className="h-4 w-4" />,
    },
    {
      id: "database" as const,
      label: "Base",
      icon: <Database className="h-4 w-4" />,
    },
  ];

  const filteredArtists = category
    ? data.artists.filter((item) => item.category === category.slug)
    : data.artists;
  const filteredArtworks = category
    ? data.artworks.filter((item) => item.category === category.slug)
    : data.artworks;
  const filteredDiscussions = category
    ? data.discussions.filter((item) => item.category === category.slug)
    : data.discussions;
  const filteredTrends = category
    ? data.trends.filter((item) => item.category === category.slug)
    : data.trends;
  const filteredEvents = category
    ? data.events.filter((item) => item.category === category.slug)
    : data.events;

  const currentTitle = category
    ? category.title
    : isCommunityPage
      ? "Communauté créative"
      : "Connexion à la base";
  const currentDescription = category
    ? `${category.description} Cette page dédiée sert de destination propre pour cet univers et reste prête à accueillir les futurs contenus.`
    : isCommunityPage
      ? "Cette page rassemble le forum, les tendances et les futurs événements de la communauté dans une expérience dédiée."
      : "Cette page centralise l’état de la base, les tables prévues et le mode de connexion du site avant le déploiement.";
  const currentImage = category
    ? category.image
    : isCommunityPage
      ? communityHeroImage
      : databaseHeroImage;

  return (
    <div className="relative min-h-screen bg-background text-foreground">
      <ArtisticPattern />
      <div className="relative z-10">
        <header className="sticky top-0 z-50 border-b border-border bg-background/85 backdrop-blur-xl">
          <div className="mx-auto flex max-w-7xl flex-col gap-4 px-6 py-4 lg:flex-row lg:items-center lg:justify-between">
            <a
              href={getStaticPagePath("home")}
              className="flex items-center gap-3"
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-primary via-secondary to-accent">
                <Sparkles className="h-5 w-5 text-primary-foreground" />
              </div>
              <div>
                <div className="text-2xl font-display italic tracking-wide text-primary">
                  Artéïa
                </div>
                <div className="text-xs text-muted-foreground">
                  Pages dédiées par univers
                </div>
              </div>
            </a>

            <nav className="flex flex-wrap gap-2">
              {pageLinks.map((link) => {
                const active = link.id === page;
                return (
                  <a
                    key={link.id}
                    href={getStaticPagePath(link.id)}
                    className={`inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm transition-colors ${
                      active
                        ? "border-primary bg-primary/10 text-primary"
                        : "border-border bg-card/40 text-muted-foreground hover:border-primary hover:text-primary"
                    }`}
                  >
                    {link.icon}
                    <span>{link.label}</span>
                  </a>
                );
              })}
            </nav>
          </div>
        </header>

        <main>
          <section className="relative overflow-hidden px-6 py-20">
            <div className="absolute inset-0 opacity-20">
              <ImageWithFallback
                src={currentImage}
                alt={currentTitle}
                className="h-full w-full object-cover"
              />
            </div>
            <div className="absolute inset-0 bg-gradient-to-b from-background/90 via-background/75 to-background" />
            <div className="absolute inset-0 bg-gradient-to-r from-primary/10 via-secondary/10 to-accent/10" />

            <div className="relative mx-auto max-w-7xl">
              <div className="mb-8 inline-flex items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-4 py-2 text-sm text-primary">
                <ExternalLink className="h-4 w-4" />
                <span>
                  {category
                    ? "Page dédiée par univers"
                    : isCommunityPage
                      ? "Page dédiée à la communauté"
                      : "Page dédiée à la base"}
                </span>
              </div>

              <div className="grid gap-8 lg:grid-cols-[1.4fr_0.8fr] lg:items-end">
                <div>
                  <h1 className="mb-6 bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-5xl font-display italic leading-tight text-transparent md:text-7xl">
                    {currentTitle}
                  </h1>
                  <p className="max-w-3xl text-xl font-accent italic text-muted-foreground md:text-2xl">
                    {currentDescription}
                  </p>
                </div>

                <div className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur">
                  <p className="text-xs uppercase tracking-[0.25em] text-primary">
                    État actuel
                  </p>
                  <div className="mt-4 space-y-3 text-sm text-muted-foreground">
                    <p>
                      Source active :{" "}
                      <span className="font-medium text-foreground">
                        {source === "supabase" ? "Supabase" : "Mock local"}
                      </span>
                    </p>
                    <p>
                      Chargement :{" "}
                      <span className="font-medium text-foreground">
                        {isLoading ? "En cours" : "Terminé"}
                      </span>
                    </p>
                    <p>
                      Publication :{" "}
                      <span className="font-medium text-foreground">
                        Pré-lancement
                      </span>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section className="px-6 py-10">
            <div className="mx-auto grid max-w-7xl gap-6 md:grid-cols-3">
              <StatCard
                label={category ? "Artistes liés" : "Artistes au total"}
                value={String(filteredArtists.length)}
              />
              <StatCard
                label={category ? "Œuvres liées" : "Œuvres au total"}
                value={String(filteredArtworks.length)}
              />
              <StatCard
                label={
                  category || isCommunityPage
                    ? "Discussions liées"
                    : "Discussions au total"
                }
                value={String(filteredDiscussions.length)}
              />
            </div>
          </section>

          {category ? (
            <section className="px-6 py-10">
              <div className="mx-auto grid max-w-7xl gap-6 lg:grid-cols-2">
                <InfoCard
                  title={`Univers ${categoryLabels[category.slug]}`}
                  body="Le style, le fond et l'identité visuelle sont prêts. Cette page servira de destination dédiée dès que les premières données seront publiées."
                />
                <InfoCard
                  title="État du contenu"
                  body="Aucune donnée réelle n'a encore été chargée : les compteurs restent à zéro et les listes attendent les futurs artistes, œuvres et discussions."
                />
              </div>
            </section>
          ) : isCommunityPage ? (
            <section className="px-6 py-10">
              <div className="mx-auto grid max-w-7xl gap-6 lg:grid-cols-2">
                <InfoCard
                  title="Forum et échanges"
                  body="La communauté aura ici sa page dédiée, distincte de l'accueil, pour regrouper sujets, tendances et événements à venir."
                />
                <InfoCard
                  title="Mode dynamique"
                  body="Dès qu'il y aura du contenu en base, cette page affichera automatiquement discussions, tags populaires et calendrier communautaire."
                />
              </div>
            </section>
          ) : (
            <section className="px-6 py-10">
              <div className="mx-auto max-w-7xl rounded-2xl border border-border bg-card/60 p-8 backdrop-blur">
                <h2 className="mb-6 text-3xl font-display italic text-foreground">
                  Tables prévues côté base
                </h2>
                <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                  {[
                    "categories",
                    "artists",
                    "artworks",
                    "forum_discussions",
                    "trend_tags",
                    "community_events",
                    "community_stats",
                  ].map((table) => (
                    <div
                      key={table}
                      className="rounded-xl border border-border bg-background/50 p-4"
                    >
                      <p className="text-sm font-medium text-foreground">
                        {table}
                      </p>
                      <p className="mt-2 text-xs text-muted-foreground">
                        Structure prête, contenu encore vide.
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </section>
          )}

          <section className="px-6 py-10">
            <div className="mx-auto max-w-7xl space-y-8">
              {isCommunityPage ? (
                <>
                  <ContentSection
                    title="Discussions"
                    emptyTitle="Aucune discussion ouverte"
                    emptyDescription="Les conversations communautaires apparaîtront ici dès les premiers échanges."
                    items={filteredDiscussions}
                    renderItem={(item) => (
                      <DiscussionPreviewCard key={item.title} item={item} />
                    )}
                  />
                  <div className="grid gap-8 lg:grid-cols-2">
                    <ContentSection
                      title="Tendances"
                      emptyTitle="Aucune tendance pour le moment"
                      emptyDescription="Les hashtags populaires s'afficheront ici lorsque la communauté commencera à publier."
                      items={filteredTrends}
                      renderItem={(item) => (
                        <TrendPreviewCard key={item.tag} item={item} />
                      )}
                    />
                    <ContentSection
                      title="Événements"
                      emptyTitle="Aucun événement planifié"
                      emptyDescription="Les rencontres, concours et projections apparaîtront ici dès qu'ils seront ajoutés."
                      items={filteredEvents}
                      renderItem={(item) => (
                        <EventPreviewCard key={item.title} item={item} />
                      )}
                    />
                  </div>
                </>
              ) : isDatabasePage ? (
                <ContentSection
                  title="Catégories configurées"
                  emptyTitle="Aucune catégorie chargée"
                  emptyDescription="Les catégories visuelles restent disponibles localement et se synchroniseront ici quand elles seront présentes en base."
                  items={data.categories}
                  renderItem={(item) => (
                    <CategoryPreviewCard key={item.slug} category={item} />
                  )}
                />
              ) : (
                <>
                  <ContentSection
                    title="Artistes"
                    emptyTitle={`Aucun artiste ${category ? getCategoryLabel(category.slug).toLowerCase() : "publié"} pour le moment`}
                    emptyDescription="Les profils apparaîtront ici dès qu'ils seront ajoutés et reliés à la base de données."
                    items={filteredArtists}
                    renderItem={(item) => (
                      <ArtistPreviewCard key={item.name} item={item} />
                    )}
                  />
                  <ContentSection
                    title="Œuvres"
                    emptyTitle={`Aucune œuvre ${category ? getCategoryLabel(category.slug).toLowerCase() : "publiée"} pour le moment`}
                    emptyDescription="Les créations visuelles, audio ou narratives seront affichées ici dès leur publication."
                    items={filteredArtworks}
                    renderItem={(item) => (
                      <ArtworkPreviewCard
                        key={`${item.title}-${item.artist}`}
                        item={item}
                      />
                    )}
                  />
                  <ContentSection
                    title="Discussions associées"
                    emptyTitle="Aucune discussion liée pour le moment"
                    emptyDescription="Les premières discussions de cet univers apparaîtront ici automatiquement."
                    items={filteredDiscussions}
                    renderItem={(item) => (
                      <DiscussionPreviewCard key={item.title} item={item} />
                    )}
                  />
                </>
              )}
            </div>
          </section>

          <section className="px-6 py-16">
            <div className="mx-auto flex max-w-7xl flex-col gap-4 rounded-2xl border border-border bg-gradient-to-br from-primary/10 via-secondary/10 to-accent/10 p-8 md:flex-row md:items-center md:justify-between">
              <div>
                <h2 className="text-3xl font-display italic text-foreground">
                  Continuer l’organisation du site
                </h2>
                <p className="mt-2 text-muted-foreground">
                  Les pages dédiées sont en place et respectent l’esthétique
                  actuelle du projet.
                </p>
              </div>
              <div className="flex flex-wrap gap-3">
                <a
                  href={getStaticPagePath("home")}
                  className="rounded-lg border border-border bg-card/60 px-6 py-3 text-sm font-medium text-foreground transition-colors hover:border-primary hover:text-primary"
                >
                  Revenir à l’accueil
                </a>
                <a
                  href={getStaticPagePath("database")}
                  className="rounded-lg bg-primary px-6 py-3 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
                >
                  Voir la base
                </a>
                <a
                  href={getStaticPagePath("admin")}
                  className="rounded-lg border border-border bg-card/60 px-6 py-3 text-sm font-medium text-foreground transition-colors hover:border-primary hover:text-primary"
                >
                  Ouvrir l’admin
                </a>
              </div>
            </div>
          </section>
        </main>
      </div>
    </div>
  );
}

function ContentSection<T>({
  title,
  emptyTitle,
  emptyDescription,
  items,
  renderItem,
}: {
  title: string;
  emptyTitle: string;
  emptyDescription: string;
  items: T[];
  renderItem: (item: T) => React.ReactNode;
}) {
  return (
    <section>
      <h2 className="mb-5 text-3xl font-display italic text-foreground">
        {title}
      </h2>
      {items.length > 0 ? (
        <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
          {items.map(renderItem)}
        </div>
      ) : (
        <EmptyPanel title={emptyTitle} description={emptyDescription} />
      )}
    </section>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur">
      <p className="text-sm text-muted-foreground">{label}</p>
      <p className="mt-3 text-4xl font-display text-primary">{value}</p>
    </div>
  );
}

function InfoCard({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-2xl border border-border bg-card/60 p-8 backdrop-blur">
      <h3 className="mb-3 text-2xl font-display text-foreground">{title}</h3>
      <p className="text-muted-foreground">{body}</p>
    </div>
  );
}

function ArtistPreviewCard({ item }: { item: Artist }) {
  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card/60 backdrop-blur">
      <div className="relative h-64">
        <ImageWithFallback
          src={item.image}
          alt={item.name}
          className="h-full w-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent" />
        <div className="absolute bottom-0 left-0 right-0 p-5">
          <span className="mb-3 inline-block rounded-full border border-primary/30 bg-primary/20 px-3 py-1 text-xs text-primary">
            {item.role}
          </span>
          <h3 className="text-2xl font-display text-foreground">{item.name}</h3>
          <p className="text-sm text-muted-foreground">{item.featuredWork}</p>
        </div>
      </div>
    </div>
  );
}

function ArtworkPreviewCard({ item }: { item: Artwork }) {
  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card/60 backdrop-blur">
      <div className="relative h-64">
        <ImageWithFallback
          src={item.image}
          alt={item.title}
          className="h-full w-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/45 to-transparent" />
        <div className="absolute bottom-0 left-0 right-0 p-5">
          <span className="mb-3 inline-block rounded-full border border-primary/30 bg-primary/20 px-3 py-1 text-xs text-primary">
            {item.medium}
          </span>
          <h3 className="text-2xl font-display text-foreground">
            {item.title}
          </h3>
          <p className="text-sm text-muted-foreground">par {item.artist}</p>
        </div>
      </div>
    </div>
  );
}

function DiscussionPreviewCard({ item }: { item: Discussion }) {
  return (
    <div className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur">
      <div className="mb-4 flex items-center justify-between gap-3">
        <span className="rounded-full border border-primary/30 bg-primary/20 px-3 py-1 text-xs text-primary">
          {getCategoryLabel(item.category)}
        </span>
        <span className="text-xs text-muted-foreground">{item.time}</span>
      </div>
      <h3 className="mb-2 text-2xl font-display text-foreground">
        {item.title}
      </h3>
      <p className="text-sm text-muted-foreground">Par {item.author}</p>
      <p className="mt-4 text-sm text-muted-foreground">
        {item.replies} réponses
      </p>
    </div>
  );
}

function TrendPreviewCard({ item }: { item: Trend }) {
  return (
    <div className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur">
      <p className="text-xl font-display text-primary">{item.tag}</p>
      <p className="mt-2 text-sm text-muted-foreground">
        {item.count} publications
      </p>
      <p className="mt-4 text-xs uppercase tracking-[0.2em] text-muted-foreground">
        {getCategoryLabel(item.category)}
      </p>
    </div>
  );
}

function EventPreviewCard({ item }: { item: EventItem }) {
  return (
    <div className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur">
      <p className="text-xs uppercase tracking-[0.2em] text-primary">
        {item.date}
      </p>
      <h3 className="mt-3 text-2xl font-display text-foreground">
        {item.title}
      </h3>
      <p className="mt-2 text-sm text-muted-foreground">
        {getCategoryLabel(item.category)}
      </p>
    </div>
  );
}

function CategoryPreviewCard({
  category,
}: {
  category: { title: string; description: string; image: string };
}) {
  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card/60 backdrop-blur">
      <div className="relative h-48">
        <ImageWithFallback
          src={category.image}
          alt={category.title}
          className="h-full w-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/30 to-transparent" />
        <div className="absolute bottom-0 left-0 right-0 p-5">
          <h3 className="text-2xl font-display text-foreground">
            {category.title}
          </h3>
        </div>
      </div>
      <div className="p-5">
        <p className="text-sm text-muted-foreground">{category.description}</p>
      </div>
    </div>
  );
}

function EmptyPanel({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="rounded-2xl border border-dashed border-border bg-card/60 p-10 text-center backdrop-blur">
      <h3 className="mb-3 text-3xl font-display italic text-foreground">
        {title}
      </h3>
      <p className="mx-auto max-w-3xl text-muted-foreground">{description}</p>
    </div>
  );
}
