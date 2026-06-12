import { useState, useEffect } from "react";
import {
  BookOpen,
  Clapperboard,
  Database,
  ExternalLink,
  Film,
  Home,
  Layers3,
  LockKeyhole,
  LogOut,
  MessageCircle,
  Music4,
  Pen,
  ShieldCheck,
  Sparkles,
  UserRound,
  UserRoundPlus,
  WandSparkles,
} from "lucide-react";
import { ImageWithFallback } from "../components/ImageWithFallback";
import { PageBackdrop } from "../components/PageBackdrop";
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
  openStaticPage,
  staticPagePaths,
  type StaticPageId,
} from "../lib/page-links";
import { ThemeToggle } from "../components/ui/ThemeToggle.tsx";
import { ArtworkUploadForm } from "../profile/ArtworkUploadForm.tsx";
import { signIn, signUp, signOut as doSignOut, getCurrentSession, onAuthChange, type AuthUser } from "../services/auth";
import { hasSupabaseEnv } from "../lib/supabase";

type MultiPageAppProps = {
  page: string;
};

function isStaticPageId(value: string): value is StaticPageId {
  return value in staticPagePaths;
}

function isAuthPage(page: StaticPageId) {
  return page === "login" || page === "signup";
}

export function MultiPageApp({ page }: MultiPageAppProps) {
  if (!isStaticPageId(page)) {
    return null;
  }

  const { data, source, isLoading } = useCommunityData();
  const category = data.categories.find((item) => item.slug === page);
  const isCommunityPage = page === "community";
  const isDatabasePage = page === "database";
  const isProfilePage = page === "profile";
  const isLoginPage = page === "login";
  const isSignupPage = page === "signup";

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

  const utilityLinks = [
    {
      id: "login" as const,
      label: "Connexion",
      icon: <LockKeyhole className="h-4 w-4" />,
    },
    {
      id: "signup" as const,
      label: "Inscription",
      icon: <UserRoundPlus className="h-4 w-4" />,
    },
    {
      id: "profile" as const,
      label: "Profil",
      icon: <UserRound className="h-4 w-4" />,
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

  const pageMeta = getPageMeta(page, category);

  return (
    <div className="relative min-h-screen bg-background text-foreground">
      <PageBackdrop page={page} />
      <div className="relative z-10">
        <header className="sticky top-0 z-50 border-b border-border bg-background/85 backdrop-blur-xl">
          <div className="mx-auto flex max-w-7xl flex-col gap-4 px-6 py-4 lg:flex-row lg:items-center lg:justify-between">
            <a
              href={getStaticPagePath("home")}
              className="flex items-center gap-3"
            >
              <div className="flex h-11 w-11 -rotate-3 items-center justify-center rounded-2xl border border-foreground/10 bg-gradient-to-br from-primary via-primary to-accent shadow-[0_12px_30px_rgba(255,106,26,0.25)]">
                <Sparkles className="h-5 w-5 text-primary-foreground" />
              </div>
              <div>
                <div className="font-display text-2xl uppercase tracking-[0.18em] text-foreground">
                  Artéïa
                </div>
                <div className="text-[11px] uppercase tracking-[0.24em] text-muted-foreground">
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
                    className={`inline-flex items-center gap-2 rounded-full border px-4 py-2 text-xs font-semibold uppercase tracking-[0.16em] transition-colors ${
                      active
                        ? "border-primary bg-primary/12 text-primary"
                        : "border-border bg-card/40 text-muted-foreground hover:border-primary hover:text-primary"
                    }`}
                  >
                    {link.icon}
                    <span>{link.label}</span>
                  </a>
                );
              })}
            </nav>

            <div className="flex flex-wrap items-center gap-2">
              <ThemeToggle />
              {utilityLinks.map((link) => {
                const active = link.id === page;
                return (
                  <a
                    key={link.id}
                    href={getStaticPagePath(link.id)}
                    className={`inline-flex items-center gap-2 rounded-full border px-4 py-2 text-xs font-semibold uppercase tracking-[0.16em] transition-colors ${
                      active
                        ? "border-primary bg-primary/12 text-primary"
                        : "border-border bg-card/40 text-muted-foreground hover:border-primary hover:text-primary"
                    }`}
                  >
                    {link.icon}
                    <span>{link.label}</span>
                  </a>
                );
              })}
            </div>
          </div>
        </header>

        <main>
          <section className="relative overflow-hidden px-6 py-20">
            <div className="absolute inset-0 bg-gradient-to-b from-background/70 via-background/62 to-background/88" />
            <div className="absolute inset-0 bg-[linear-gradient(120deg,rgba(255,106,26,0.16),transparent_36%,rgba(40,216,255,0.12)_74%,transparent)]" />

            <div className="relative mx-auto max-w-7xl">
              <div className="street-kicker mb-8">
                <ExternalLink className="h-4 w-4" />
                <span>{pageMeta.kicker}</span>
              </div>

              <div className="grid gap-8 lg:grid-cols-[1.4fr_0.8fr] lg:items-end">
                <div>
                  <h1 className="street-title mb-6 text-5xl leading-[0.95] md:text-7xl">
                    {pageMeta.title}
                  </h1>
                  <p className="street-copy max-w-3xl text-xl leading-8 md:text-2xl">
                    {pageMeta.description}
                  </p>
                  <div className="mt-8 flex flex-wrap gap-3">
                    {pageMeta.tags.map((tag) => (
                      <span key={tag} className="street-chip">
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>

                <div className="street-panel p-6">
                  <p className="text-xs uppercase tracking-[0.3em] text-primary">
                    Ambiance active
                  </p>
                  <div className="mt-4 space-y-3 text-sm text-muted-foreground">
                    <p>
                      Univers :{" "}
                      <span className="font-medium text-foreground">
                        {pageMeta.panelLineOne}
                      </span>
                    </p>
                    <p>
                      Mouvement :{" "}
                      <span className="font-medium text-foreground">
                        {pageMeta.panelLineTwo}
                      </span>
                    </p>
                    <p>
                      Source active :{" "}
                      <span className="font-medium text-foreground">
                        {source === "supabase" ? "Supabase" : "Mock local"}
                      </span>
                    </p>
                    <p>
                      Etat :{" "}
                      <span className="font-medium text-foreground">
                        {isLoading ? "Chargement" : "Pret a evoluer"}
                      </span>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>

          {isLoginPage || isSignupPage ? (
            <AuthPageSection page={page} />
          ) : isProfilePage ? (
            <ProfilePageSection />
          ) : (
            <>
              <section className="px-6 py-10">
                <div className="mx-auto grid max-w-7xl gap-6 md:grid-cols-3">
                  <StatCard
                    label={category ? "Artistes lies" : "Artistes au total"}
                    value={String(filteredArtists.length)}
                  />
                  <StatCard
                    label={category ? "Oeuvres liees" : "Oeuvres au total"}
                    value={String(filteredArtworks.length)}
                  />
                  <StatCard
                    label={
                      category || isCommunityPage
                        ? "Discussions liees"
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
                      body={pageMeta.infoCards[0]}
                    />
                    <InfoCard
                      title="Direction visuelle"
                      body={pageMeta.infoCards[1]}
                    />
                  </div>
                </section>
              ) : isCommunityPage ? (
                <section className="px-6 py-10">
                  <div className="mx-auto grid max-w-7xl gap-6 lg:grid-cols-2">
                    <InfoCard
                      title="Forum et echanges"
                      body={pageMeta.infoCards[0]}
                    />
                    <InfoCard
                      title="Scene communautaire"
                      body={pageMeta.infoCards[1]}
                    />
                  </div>
                </section>
              ) : (
                <section className="px-6 py-10">
                  <div className="street-panel mx-auto max-w-7xl p-8">
                    <h2 className="street-title mb-6 text-3xl">
                      Tables prevues cote base
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
                        <div key={table} className="street-panel-soft p-4">
                          <p className="text-sm font-medium text-foreground">
                            {table}
                          </p>
                          <p className="mt-2 text-xs text-muted-foreground">
                            Structure prete, contenu encore vide.
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
                        emptyDescription="Les conversations communautaires apparaitront ici des les premiers echanges."
                        items={filteredDiscussions}
                        renderItem={(item) => (
                          <DiscussionPreviewCard key={item.title} item={item} />
                        )}
                      />
                      <div className="grid gap-8 lg:grid-cols-2">
                        <ContentSection
                          title="Tendances"
                          emptyTitle="Aucune tendance pour le moment"
                          emptyDescription="Les hashtags populaires s'afficheront ici lorsque la communaute commencera a publier."
                          items={filteredTrends}
                          renderItem={(item) => (
                            <TrendPreviewCard key={item.tag} item={item} />
                          )}
                        />
                        <ContentSection
                          title="Evenements"
                          emptyTitle="Aucun evenement planifie"
                          emptyDescription="Les rencontres, concours et projections apparaitront ici des qu'ils seront ajoutes."
                          items={filteredEvents}
                          renderItem={(item) => (
                            <EventPreviewCard key={item.title} item={item} />
                          )}
                        />
                      </div>
                    </>
                  ) : isDatabasePage ? (
                    <ContentSection
                      title="Categories configurees"
                      emptyTitle="Aucune categorie chargee"
                      emptyDescription="Les categories visuelles restent disponibles localement et se synchroniseront ici quand elles seront presentes en base."
                      items={data.categories}
                      renderItem={(item) => (
                        <CategoryPreviewCard key={item.slug} category={item} />
                      )}
                    />
                  ) : (
                    <>
                      <ContentSection
                        title="Artistes"
                        emptyTitle={`Aucun artiste ${category ? getCategoryLabel(category.slug).toLowerCase() : "publie"} pour le moment`}
                        emptyDescription="Les profils apparaitront ici des qu'ils seront ajoutes et relies a la base de donnees."
                        items={filteredArtists}
                        renderItem={(item) => (
                          <ArtistPreviewCard key={item.name} item={item} />
                        )}
                      />
                      <ContentSection
                        title="Oeuvres"
                        emptyTitle={`Aucune oeuvre ${category ? getCategoryLabel(category.slug).toLowerCase() : "publiee"} pour le moment`}
                        emptyDescription="Les creations visuelles, audio ou narratives seront affichees ici des leur publication."
                        items={filteredArtworks}
                        renderItem={(item) => (
                          <ArtworkPreviewCard
                            key={`${item.title}-${item.artist}`}
                            item={item}
                          />
                        )}
                      />
                      <ContentSection
                        title="Discussions associees"
                        emptyTitle="Aucune discussion liee pour le moment"
                        emptyDescription="Les premieres discussions de cet univers apparaitront ici automatiquement."
                        items={filteredDiscussions}
                        renderItem={(item) => (
                          <DiscussionPreviewCard key={item.title} item={item} />
                        )}
                      />
                    </>
                  )}
                </div>
              </section>
            </>
          )}

          <section className="px-6 py-16">
            <div className="street-panel mx-auto flex max-w-7xl flex-col gap-4 bg-gradient-to-br from-primary/10 via-background to-accent/10 p-8 md:flex-row md:items-center md:justify-between">
              <div>
                <h2 className="street-title text-3xl">
                  Continuer l'organisation du site
                </h2>
                <p className="mt-2 text-muted-foreground">
                  Les pages dediees sont en place, animees et coherentes avec
                  le theme de chaque univers.
                </p>
              </div>
              <div className="flex flex-wrap gap-3">
                <a
                  href={getStaticPagePath("home")}
                  className="rounded-xl border border-border bg-card/60 px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-primary hover:text-primary"
                >
                  Revenir à l’accueil
                </a>
                <a
                  href={getStaticPagePath("database")}
                  className="rounded-xl border border-primary/30 bg-primary px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-primary-foreground transition-opacity hover:opacity-90"
                >
                  Voir la base
                </a>
                <a
                  href={getStaticPagePath("signup")}
                  className="rounded-xl border border-border bg-card/60 px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-primary hover:text-primary"
                >
                  Creer un compte
                </a>
                <a
                  href={getStaticPagePath("admin")}
                  className="rounded-xl border border-border bg-card/60 px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-primary hover:text-primary"
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

function getPageMeta(
  page: StaticPageId,
  category?: {
    slug: Exclude<StaticPageId, "home" | "community" | "database" | "login" | "signup" | "profile" | "admin">;
    title: string;
    description: string;
  },
) {
  if (category) {
    const copyByCategory: Record<string, { tags: string[]; panelLineOne: string; panelLineTwo: string; infoCards: string[] }> = {
      music: {
        tags: ["notes en chute", "slash katana", "basse brute"],
        panelLineOne: "tempo nocturne",
        panelLineTwo: "notes qui tombent et lames lumineuses",
        infoCards: [
          "La page musique devient une scene vivante, entre pluie de notes, pulsation urbaine et sensation de mouvement permanent.",
          "Le fond anime raconte un univers sonique coupe au katana, pour donner a l'utilisateur un impact immediat des l'entree sur la page.",
        ],
      },
      "visual-art": {
        tags: ["pigments volants", "mur peint", "matiere brute"],
        panelLineOne: "atelier de rue",
        panelLineTwo: "eclats de couleur et textures peintes",
        infoCards: [
          "Cette page assume une vibe d'atelier mural vivant, avec des masses de couleur, de la matiere et un vrai souffle de creation.",
          "L'image de fond et les overlays donnent une sensation d'espace artistique habite, sans tomber dans l'effet decoratif gratuit.",
        ],
      },
      manga: {
        tags: ["speed lines", "fragments d'encre", "panels dechires"],
        panelLineOne: "cadre narratif",
        panelLineTwo: "lignes de vitesse et tension graphique",
        infoCards: [
          "La page manga travaille la dramaturgie, le rythme et le decoupage visuel avec une energie plus nerveuse et plus directe.",
          "Le fond bouge avec des panneaux, des traces d'encre et une dynamique proche d'une page qui explose hors du cadre.",
        ],
      },
      film: {
        tags: ["projecteur", "pellicule", "brouillard"],
        panelLineOne: "set independant",
        panelLineTwo: "faisceaux, cadres et grain cinema",
        infoCards: [
          "La page films prend une direction plus cinematographique, avec une impression de plateau, de pluie et de halo lumineux.",
          "L'animation reste subtile pour garder un rendu premium, comme un decor de film qui respire doucement derriere l'interface.",
        ],
      },
      literature: {
        tags: ["pages volantes", "fumee d'encre", "fragments de texte"],
        panelLineOne: "couloir litteraire",
        panelLineTwo: "lettres et pages en suspension",
        infoCards: [
          "La page litterature cherche une atmosphere plus mentale, plus poetique, ou les signes et les pages circulent comme des souvenirs.",
          "Le fond anime donne l'impression qu'un texte vivant se forme et se disperse autour du lecteur, dans une ambiance sombre et elegante.",
        ],
      },
      animation: {
        tags: ["frames mouvants", "traces lumineuses", "celluloid"],
        panelLineOne: "studio dynamique",
        panelLineTwo: "cadres mobiles et traines de lumiere",
        infoCards: [
          "La page animation devait absolument sembler vivante. Les arrieres-plans bougent comme un pipeline creatif deja en marche.",
          "Le rendu evoque des calques, des frames et un atelier de motion qui tourne en permanence derriere la surface du site.",
        ],
      },
    };

    const copy = copyByCategory[category.slug];

    return {
      kicker: "Page dediee par univers",
      title: category.title,
      description: `${category.description} Cette destination a maintenant un fond anime lie a son theme pour donner une vraie sensation de monde actif et coherent.`,
      tags: copy.tags,
      panelLineOne: copy.panelLineOne,
      panelLineTwo: copy.panelLineTwo,
      infoCards: copy.infoCards,
    };
  }

  if (page === "community") {
    return {
      kicker: "Page dediee a la communaute",
      title: "Communaute creative",
      description:
        "Le forum, les tendances et les futurs evenements se regroupent ici dans une scene plus vivante, plus urbaine, plus collective.",
      tags: ["echanges", "rumeurs creatives", "impulsion sociale"],
      panelLineOne: "forum central",
      panelLineTwo: "symboles et signaux communautaires",
      infoCards: [
        "La page communaute agit comme une place centrale. Le fond visuel renforce l'idee d'energie collective et de circulation permanente.",
        "Les futures discussions, tendances et evenements disposeront deja d'un ecrin vivant, pret a monter en intensite avec le contenu reel.",
      ],
    };
  }

  if (page === "database") {
    return {
      kicker: "Page dediee a la base",
      title: "Connexion a la base",
      description:
        "Cette page montre l'etat des structures de donnees, mais dans une ambiance techno-punk plus immersive et moins froide.",
      tags: ["data vault", "flux lumineux", "structure interne"],
      panelLineOne: "infrastructure vivante",
      panelLineTwo: "pluie de donnees et signaux systeme",
      infoCards: [
        "Le fond de la page base n'est plus un simple decor: il evoque une chambre de donnees, un coeur technique deja sous tension.",
        "Cela aide a faire sentir que meme les couches invisibles du projet appartiennent a un monde coherent et ambitieux.",
      ],
    };
  }

  if (page === "login") {
    return {
      kicker: "Acces a l'univers",
      title: "Connexion",
      description:
        "Entrer dans Artéïa doit deja donner une sensation d'intensite. Cette page ouvre la porte du projet avec un fond vivant et une interface plus forte.",
      tags: ["acces securise", "signal", "porte d'entree"],
      panelLineOne: "portail utilisateur",
      panelLineTwo: "scans lumineux et seuil securise",
      infoCards: [],
    };
  }

  if (page === "signup") {
    return {
      kicker: "Creation de compte",
      title: "Inscription",
      description:
        "Cette page marque le debut du parcours createur. Elle doit inspirer confiance, desir et projection dans un univers plus grand que l'ecran.",
      tags: ["nouvelle identite", "depart", "projection creative"],
      panelLineOne: "creation de profil",
      panelLineTwo: "fragments lumineux et impulsion d'arrivee",
      infoCards: [],
    };
  }

  return {
    kicker: "Espace personnel",
    title: "Profil creatif",
    description:
      "Le profil devient une vraie page annexe, avec une direction visuelle propre, pour faire sentir a l'utilisateur qu'il entre dans son espace de creation.",
    tags: ["identite", "projets", "presence"],
    panelLineOne: "quartier general creatif",
    panelLineTwo: "formes identitaires et mouvement subtil",
    infoCards: [],
  };
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
      <h2 className="street-title mb-5 text-3xl">
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
    <div className="street-panel p-6">
      <p className="text-sm text-muted-foreground">{label}</p>
      <p className="street-title mt-3 text-4xl text-primary">{value}</p>
    </div>
  );
}

function InfoCard({ title, body }: { title: string; body: string }) {
  return (
    <div className="street-panel p-8">
      <h3 className="street-title mb-3 text-2xl">{title}</h3>
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

function AuthPageSection({ page }: { page: StaticPageId }) {
  const isLoginPage = page === "login";
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  useEffect(() => {
    getCurrentSession().then(({ user }) => {
      if (user) setAuthUser(user);
    });
    const sub = onAuthChange((user) => setAuthUser(user));
    return () => sub.unsubscribe();
  }, []);

  function showMessage(type: "success" | "error", text: string) {
    setMessage({ type, text });
    setTimeout(() => setMessage(null), 5000);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email.trim() || !password.trim()) {
      showMessage("error", "Email et mot de passe requis.");
      return;
    }
    setIsSubmitting(true);
    setMessage(null);
    try {
      if (isLoginPage) {
        const { user, error } = await signIn(email.trim(), password);
        if (error) {
          showMessage("error", error);
        } else if (user) {
          setAuthUser(user);
          showMessage("success", "Connecté ! Bienvenue dans Artéïa.");
        }
      } else {
        const { user, error } = await signUp(email.trim(), password);
        if (error) {
          showMessage("error", error);
        } else if (user) {
          showMessage("success", "Compte créé ! Vérifie tes emails pour confirmer ton inscription.");
        }
      }
    } catch (err) {
      showMessage("error", err instanceof Error ? err.message : "Erreur de connexion.");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleLogout() {
    await doSignOut();
    setAuthUser(null);
  }

  const inputCls = "w-full rounded-xl border border-border bg-background px-4 py-3 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground/50 focus:border-primary";

  return (
    <>
      <section className="px-6 py-10">
        <div className="mx-auto grid max-w-7xl gap-6 md:grid-cols-3">
          <StatCard label="Acces" value={authUser ? "Connecte" : (isLoginPage ? "24/7" : "Nouveau")} />
          <StatCard label="Parcours" value={authUser ? "Actif" : (isLoginPage ? "Secure" : "Createur")} />
          <StatCard label="Etat" value={authUser ? "Authentifie" : "Pret"} />
        </div>
      </section>

      {message && (
        <section className="px-6 py-0">
          <div className={`mx-auto max-w-7xl rounded-xl border px-5 py-4 text-sm backdrop-blur ${
            message.type === "success"
              ? "border-primary/30 bg-primary/10 text-primary"
              : "border-red-500/30 bg-red-500/10 text-red-300"
          }`}>
            {message.text}
          </div>
        </section>
      )}

      <section className="px-6 py-10">
        <div className="mx-auto grid max-w-7xl gap-8 lg:grid-cols-[0.95fr_1.05fr]">
          <div className="street-panel p-8">
            <div className="mb-6 inline-flex items-center gap-2 rounded-md border border-primary/30 bg-primary/10 px-4 py-2 text-xs font-semibold uppercase tracking-[0.24em] text-primary">
              {isLoginPage ? <LockKeyhole className="h-4 w-4" /> : <UserRoundPlus className="h-4 w-4" />}
              <span>{isLoginPage ? "Connexion" : "Inscription"}</span>
            </div>
            <h2 className="street-title mb-4 text-3xl">
              {authUser
                ? `Connecte en tant que ${authUser.email}`
                : isLoginPage
                  ? "Reprendre le controle de ton univers"
                  : "Donne une forme a ta presence creative"}
            </h2>
            <p className="street-copy text-lg leading-8">
              {authUser
                ? "Tu es authentifie. Tes soumissions seront envoyees directement a la base Supabase."
                : isLoginPage
                  ? "Retrouve ton espace, tes projets, tes brouillons et les liens entre tes univers artistiques dans une entree plus forte et plus vivante."
                  : "Cree ton identite, choisis ton terrain, commence a publier et a faire exister ton univers dans une scene qui a deja du souffle."}
            </p>
            <div className="mt-8 grid gap-4 md:grid-cols-2">
              <InfoCard
                title={hasSupabaseEnv ? "Supabase actif" : "Configuration requise"}
                body={hasSupabaseEnv
                  ? "Supabase est configure. Les formulaires envoient les donnees directement a la base."
                  : "Ajoute VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans .env pour activer la base."}
              />
              <InfoCard
                title="Profil"
                body={authUser
                  ? "Tu peux maintenant publier des oeuvres, creer des profils artistes et lancer des discussions."
                  : "Connecte-toi ou cree un compte pour commencer a contribuer."}
              />
            </div>
          </div>

          <div className="street-panel p-8">
            {authUser ? (
              <div className="space-y-6">
                <h2 className="street-title mb-4 text-3xl flex items-center gap-3">
                  <ShieldCheck className="h-6 w-6 text-primary" />
                  Authentifie
                </h2>
                <p className="text-muted-foreground">
                  Tu es connecte avec <span className="font-medium text-foreground">{authUser.email}</span>.
                </p>
                <p className="text-sm text-muted-foreground">
                  Va sur la page <a href={getStaticPagePath("profile")} className="text-primary underline">Profil</a> pour soumettre du contenu, ou utilise l'admin si tu as les droits.
                </p>
                <button
                  onClick={handleLogout}
                  className="inline-flex items-center gap-2 rounded-xl border border-border bg-card/60 px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-red-500 hover:text-red-400"
                >
                  <LogOut className="h-4 w-4" />
                  Se deconnecter
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-5">
                <h2 className="street-title mb-4 text-3xl">
                  {isLoginPage ? "Entrer" : "Commencer"}
                </h2>
                <div>
                  <label className="mb-2 block text-xs uppercase tracking-[0.2em] text-muted-foreground">Email *</label>
                  <input
                    className={inputCls}
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="ton.email@arteia.fr"
                    required
                  />
                </div>
                <div>
                  <label className="mb-2 block text-xs uppercase tracking-[0.2em] text-muted-foreground">
                    {isLoginPage ? "Mot de passe *" : "Mot de passe *"}
                  </label>
                  <input
                    className={inputCls}
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                    minLength={6}
                  />
                </div>
                {!isLoginPage && (
                  <div>
                    <label className="mb-2 block text-xs uppercase tracking-[0.2em] text-muted-foreground">
                      Nom creatif (optionnel)
                    </label>
                    <input
                      className={inputCls}
                      type="text"
                      value={displayName}
                      onChange={(e) => setDisplayName(e.target.value)}
                      placeholder="Ton alias ou nom d'artiste"
                    />
                  </div>
                )}
                {!hasSupabaseEnv && (
                  <div className="rounded-xl border border-yellow-500/30 bg-yellow-500/10 px-4 py-3 text-xs text-yellow-400">
                    ⚠️ Supabase non configure. Ajoute les variables dans .env pour activer l'auth.
                  </div>
                )}
                <div className="flex flex-wrap gap-3 pt-2">
                  <button
                    type="submit"
                    disabled={isSubmitting || !hasSupabaseEnv}
                    className="rounded-xl border border-primary/30 bg-primary px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
                  >
                    {isSubmitting
                      ? "En cours..."
                      : (isLoginPage ? "Se connecter" : "Creer mon compte")}
                  </button>
                  <button
                    type="button"
                    className="rounded-xl border border-border bg-card/60 px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-foreground transition-colors hover:border-primary hover:text-primary"
                    onClick={() => openStaticPage(isLoginPage ? "signup" : "login")}
                  >
                    {isLoginPage ? "Pas encore inscrit ?" : "J'ai deja un compte"}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      </section>
    </>
  );
}

function ProfilePageSection() {
  return (
    <section className="px-6 py-10">
      <div className="mx-auto max-w-4xl">
        <ArtworkUploadForm />
      </div>
    </section>
  );
}

function FieldCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="street-panel-soft p-4">
      <p className="mb-2 text-xs uppercase tracking-[0.2em] text-muted-foreground">
        {label}
      </p>
      <p className="text-sm text-foreground">{value}</p>
    </div>
  );
}
