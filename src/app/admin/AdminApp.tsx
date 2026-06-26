import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  artistSchema,
  artworkSchema,
  discussionSchema,
  trendSchema,
  eventSchema,
  statSchema,
  loginSchema,
  type ArtistForm,
  type ArtworkForm,
  type DiscussionForm,
  type TrendForm,
  type EventForm,
  type StatForm,
  type LoginForm,
} from "./admin-schemas";
import { useEffect, useState } from "react";
import {
  LockKeyhole,
  LogOut,
  ShieldAlert,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import type { Session } from "@supabase/supabase-js";
import { categories } from "../data/community";
import { hasSupabaseEnv } from "../lib/supabase";
import { getStaticPagePath } from "../lib/page-links";
import type { AdminProfile } from "./admin-service";
import {
  createArtist,
  createArtwork,
  createDiscussion,
  createEvent,
  createTrend,
  getAdminSession,
  getOwnAdminProfile,
  signInAdmin,
  signOutAdmin,
  signUpAdmin,
  subscribeToAdminAuth,
  syncDefaultCategories,
  upsertStat,
} from "./admin-service";
import { ThemeToggle } from "../components/ui/ThemeToggle.tsx";

const initialArtist: ArtistForm = {
  name: "",
  category_slug: "music",
  role: "",
  image: "",
  featured_work: "",
};

const initialArtwork: ArtworkForm = {
  title: "",
  artist_name: "",
  category_slug: "music",
  medium: "",
  image: "",
  height: "aspect-square",
};

const initialDiscussion: DiscussionForm = {
  title: "",
  author_name: "",
  category_slug: "music",
  time_label: "Aujourd’hui",
  trending: false,
};

const initialTrend: TrendForm = {
  tag: "",
  category_slug: "music",
  sort_order: 1,
};

const initialEvent: EventForm = {
  title: "",
  date_label: "",
  category_slug: "music",
  sort_order: 1,
};

const initialStat: StatForm = {
  label: "",
  number_label: "0",
  sort_order: 1,
};

type FlashMessage =
  | {
      type: "success" | "error" | "info";
      text: string;
    }
  | null;

export function AdminApp() {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<AdminProfile | null>(null);
  const [isBooting, setIsBooting] = useState(true);
  const [isBusy, setIsBusy] = useState(false);
  const [flash, setFlash] = useState<FlashMessage>(null);

  const loginForm = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  const artistForm = useForm<ArtistForm>({
    resolver: zodResolver(artistSchema),
    defaultValues: initialArtist,
  });

  const artworkForm = useForm<ArtworkForm>({
    resolver: zodResolver(artworkSchema),
    defaultValues: initialArtwork,
  });

  const discussionForm = useForm<DiscussionForm>({
    resolver: zodResolver(discussionSchema),
    defaultValues: initialDiscussion,
  });

  const trendForm = useForm<TrendForm>({
    resolver: zodResolver(trendSchema),
    defaultValues: initialTrend,
  });

  const eventForm = useForm<EventForm>({
    resolver: zodResolver(eventSchema),
    defaultValues: initialEvent,
  });

  const statForm = useForm<StatForm>({
    resolver: zodResolver(statSchema),
    defaultValues: initialStat,
  });

  const isAdmin = profile?.role === "admin";

  useEffect(() => {
    if (!hasSupabaseEnv) {
      setIsBooting(false);
      return;
    }

    const bootstrap = async () => {
      try {
        const currentSession = await getAdminSession();
        await hydrateSession(currentSession);
      } catch (error) {
        setFlash({
          type: "error",
          text: error instanceof Error ? error.message : "Erreur de session.",
        });
      } finally {
        setIsBooting(false);
      }
    };

    bootstrap();

    const { data } = subscribeToAdminAuth(async (nextSession) => {
      await hydrateSession(nextSession);
    });

    return () => {
      data.subscription.unsubscribe();
    };
  }, []);

  async function hydrateSession(currentSession: Session | null) {
    setSession(currentSession);

    if (!currentSession) {
      setProfile(null);
      return;
    }

    try {
      const nextProfile = await getOwnAdminProfile(currentSession.user.id);
      setProfile(nextProfile);
    } catch (error) {
      setProfile(null);
      setFlash({
        type: "error",
        text:
          error instanceof Error
            ? error.message
            : "Impossible de charger le profil admin.",
      });
    }
  }

  async function runAction(
    action: () => Promise<void>,
    successText: string
  ) {
    setIsBusy(true);
    setFlash(null);

    try {
      await action();
      setFlash({ type: "success", text: successText });
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : "Une erreur inconnue est survenue.";
      setFlash({ type: "error", text: message });
    } finally {
      setIsBusy(false);
    }
  }

  return (
    <div className="min-h-screen bg-background text-foreground">
      <div className="border-b border-border bg-background/85 backdrop-blur-xl">
        <div className="mx-auto flex max-w-7xl flex-col gap-4 px-6 py-5 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-primary via-secondary to-accent">
              <ShieldCheck className="h-5 w-5 text-primary-foreground" />
            </div>
            <div>
              <h1
                className="text-2xl italic tracking-wide text-primary"
                style={{ fontFamily: "'Alien Block', cursive" }}
              >
                Admin Artéïa
              </h1>
              <p className="text-sm text-muted-foreground">
                Interface d’administration sécurisée pour remplir la base.
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <ThemeToggle />
            <a
              href={getStaticPagePath("home")}
              className="rounded-lg border border-border px-4 py-2 text-sm transition-colors hover:border-primary hover:text-primary"
            >
              Accueil
            </a>
            <a
              href={getStaticPagePath("database")}
              className="rounded-lg border border-border px-4 py-2 text-sm transition-colors hover:border-primary hover:text-primary"
            >
              Base
            </a>
            {session ? (
              <button
                className="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground transition-opacity hover:opacity-90"
                onClick={() =>
                  runAction(() => signOutAdmin(), "Déconnexion réussie.")
                }
                disabled={isBusy}
              >
                <LogOut className="h-4 w-4" />
                Déconnexion
              </button>
            ) : null}
          </div>
        </div>
      </div>

      <main className="mx-auto max-w-7xl px-6 py-10">
        {!hasSupabaseEnv ? (
          <SetupPanel />
        ) : isBooting ? (
          <InfoPanel
            title="Connexion en cours"
            body="Vérification de la session et du rôle administrateur..."
          />
        ) : !session ? (
          <div className="grid gap-6 lg:grid-cols-[1fr_1.2fr]">
            <InfoPanel
              title="Accès protégé"
              body="Connecte-toi avec un compte Supabase. Ensuite, ce compte devra être promu au rôle admin dans la table `profiles` pour accéder aux formulaires d’écriture."
            />
            <AdminCard title="Connexion administrateur">
              <form
                className="space-y-4"
                onSubmit={loginForm.handleSubmit((values) => {
                  runAction(
                    () => signInAdmin(values.email, values.password),
                    "Connexion réussie."
                  );
                })}
              >
                <Field label="Email">
                  <input
                    className={inputClassName}
                    type="email"
                    {...loginForm.register("email")}
                    placeholder="admin@arteia.com"
                  />
                  {loginForm.formState.errors.email && (
                    <p className="mt-1 text-xs text-red-400">
                      {loginForm.formState.errors.email.message}
                    </p>
                  )}
                </Field>
                <Field label="Mot de passe">
                  <input
                    className={inputClassName}
                    type="password"
                    {...loginForm.register("password")}
                    placeholder="••••••••"
                  />
                  {loginForm.formState.errors.password && (
                    <p className="mt-1 text-xs text-red-400">
                      {loginForm.formState.errors.password.message}
                    </p>
                  )}
                </Field>
                <div className="flex flex-wrap gap-3">
                  <button
                    type="submit"
                    className="rounded-lg bg-primary px-5 py-3 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
                    disabled={isBusy}
                  >
                    Se connecter
                  </button>
                  <button
                    type="button"
                    className="rounded-lg border border-border px-5 py-3 text-sm transition-colors hover:border-primary hover:text-primary disabled:opacity-50"
                    onClick={() =>
                      loginForm.handleSubmit((values) =>
                        runAction(
                          () => signUpAdmin(values.email, values.password),
                          "Compte créé. Il devra ensuite être promu au rôle admin dans Supabase."
                        )
                      )()
                    }
                    disabled={isBusy}
                  >
                    Créer un compte
                  </button>
                </div>
              </form>
            </AdminCard>
          </div>
        ) : !isAdmin ? (
          <AccessDeniedPanel
            email={profile?.email ?? session.user.email ?? "admin"}
          />
        ) : (
          <div className="space-y-8">
            <div className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
              <InfoPanel
                title="Session admin active"
                body={`Connecté en tant que ${profile?.email ?? session.user.email ?? "admin"}. Le rôle ${profile?.role ?? "admin"} permet maintenant d’écrire en base.`}
              />
              <AdminCard title="Initialisation rapide">
                <p className="mb-4 text-sm text-muted-foreground">
                  Commence par injecter les catégories visuelles de base dans
                  Supabase.
                </p>
                <button
                  className="inline-flex items-center gap-2 rounded-lg bg-primary px-5 py-3 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
                  onClick={() =>
                    runAction(
                      () => syncDefaultCategories(),
                      "Catégories synchronisées avec succès."
                    )
                  }
                  disabled={isBusy}
                >
                  <Sparkles className="h-4 w-4" />
                  Initialiser les catégories
                </button>
              </AdminCard>
            </div>

            <div className="grid gap-6 xl:grid-cols-2">
              {/* === Artiste === */}
              <AdminCard title="Ajouter un artiste">
                <form
                  className="space-y-4"
                  onSubmit={artistForm.handleSubmit((values) => {
                    runAction(async () => {
                      await createArtist(values);
                      artistForm.reset(initialArtist);
                    }, "Artiste ajouté.");
                  })}
                >
                  <Field label="Nom">
                    <input
                      className={inputClassName}
                      {...artistForm.register("name")}
                    />
                    {artistForm.formState.errors.name && (
                      <p className="mt-1 text-xs text-red-400">
                        {artistForm.formState.errors.name.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Catégorie">
                    <Controller
                      name="category_slug"
                      control={artistForm.control}
                      render={({ field }) => (
                        <CategorySelect
                          value={field.value}
                          onChange={field.onChange}
                        />
                      )}
                    />
                  </Field>
                  <Field label="Rôle">
                    <input
                      className={inputClassName}
                      {...artistForm.register("role")}
                    />
                    {artistForm.formState.errors.role && (
                      <p className="mt-1 text-xs text-red-400">
                        {artistForm.formState.errors.role.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Image URL">
                    <input
                      className={inputClassName}
                      {...artistForm.register("image")}
                    />
                    {artistForm.formState.errors.image && (
                      <p className="mt-1 text-xs text-red-400">
                        {artistForm.formState.errors.image.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Œuvre mise en avant">
                    <input
                      className={inputClassName}
                      {...artistForm.register("featured_work")}
                    />
                    {artistForm.formState.errors.featured_work && (
                      <p className="mt-1 text-xs text-red-400">
                        {artistForm.formState.errors.featured_work.message}
                      </p>
                    )}
                  </Field>
                  <SubmitButton
                    disabled={isBusy || !artistForm.formState.isValid}
                  >
                    Ajouter l’artiste
                  </SubmitButton>
                </form>
              </AdminCard>

              {/* === Œuvre === */}
              <AdminCard title="Ajouter une œuvre">
                <form
                  className="space-y-4"
                  onSubmit={artworkForm.handleSubmit((values) => {
                    runAction(async () => {
                      await createArtwork(values);
                      artworkForm.reset(initialArtwork);
                    }, "Œuvre ajoutée.");
                  })}
                >
                  <Field label="Titre">
                    <input
                      className={inputClassName}
                      {...artworkForm.register("title")}
                    />
                    {artworkForm.formState.errors.title && (
                      <p className="mt-1 text-xs text-red-400">
                        {artworkForm.formState.errors.title.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Nom de l’artiste">
                    <input
                      className={inputClassName}
                      {...artworkForm.register("artist_name")}
                    />
                    {artworkForm.formState.errors.artist_name && (
                      <p className="mt-1 text-xs text-red-400">
                        {artworkForm.formState.errors.artist_name.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Catégorie">
                    <Controller
                      name="category_slug"
                      control={artworkForm.control}
                      render={({ field }) => (
                        <CategorySelect
                          value={field.value}
                          onChange={field.onChange}
                        />
                      )}
                    />
                  </Field>
                  <Field label="Medium">
                    <input
                      className={inputClassName}
                      {...artworkForm.register("medium")}
                    />
                    {artworkForm.formState.errors.medium && (
                      <p className="mt-1 text-xs text-red-400">
                        {artworkForm.formState.errors.medium.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Image URL">
                    <input
                      className={inputClassName}
                      {...artworkForm.register("image")}
                    />
                    {artworkForm.formState.errors.image && (
                      <p className="mt-1 text-xs text-red-400">
                        {artworkForm.formState.errors.image.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Format">
                    <input
                      className={inputClassName}
                      {...artworkForm.register("height")}
                    />
                    {artworkForm.formState.errors.height && (
                      <p className="mt-1 text-xs text-red-400">
                        {artworkForm.formState.errors.height.message}
                      </p>
                    )}
                  </Field>
                  <SubmitButton
                    disabled={isBusy || !artworkForm.formState.isValid}
                  >
                    Ajouter l’œuvre
                  </SubmitButton>
                </form>
              </AdminCard>

              {/* === Discussion === */}
              <AdminCard title="Ajouter une discussion">
                <form
                  className="space-y-4"
                  onSubmit={discussionForm.handleSubmit((values) => {
                    runAction(async () => {
                      await createDiscussion(values);
                      discussionForm.reset(initialDiscussion);
                    }, "Discussion ajoutée.");
                  })}
                >
                  <Field label="Titre">
                    <input
                      className={inputClassName}
                      {...discussionForm.register("title")}
                    />
                    {discussionForm.formState.errors.title && (
                      <p className="mt-1 text-xs text-red-400">
                        {discussionForm.formState.errors.title.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Auteur">
                    <input
                      className={inputClassName}
                      {...discussionForm.register("author_name")}
                    />
                    {discussionForm.formState.errors.author_name && (
                      <p className="mt-1 text-xs text-red-400">
                        {discussionForm.formState.errors.author_name.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Catégorie">
                    <Controller
                      name="category_slug"
                      control={discussionForm.control}
                      render={({ field }) => (
                        <CategorySelect
                          value={field.value}
                          onChange={field.onChange}
                        />
                      )}
                    />
                  </Field>
                  <Field label="Label temps">
                    <input
                      className={inputClassName}
                      {...discussionForm.register("time_label")}
                    />
                    {discussionForm.formState.errors.time_label && (
                      <p className="mt-1 text-xs text-red-400">
                        {discussionForm.formState.errors.time_label.message}
                      </p>
                    )}
                  </Field>
                  <label className="flex items-center gap-3 text-sm text-muted-foreground">
                    <input
                      type="checkbox"
                      {...discussionForm.register("trending")}
                    />
                    Marquer comme tendance
                  </label>
                  <SubmitButton
                    disabled={isBusy || !discussionForm.formState.isValid}
                  >
                    Ajouter la discussion
                  </SubmitButton>
                </form>
              </AdminCard>

              {/* === Tendance === */}
              <AdminCard title="Ajouter une tendance">
                <form
                  className="space-y-4"
                  onSubmit={trendForm.handleSubmit((values) => {
                    runAction(async () => {
                      await createTrend(values);
                      trendForm.reset(initialTrend);
                    }, "Tendance ajoutée.");
                  })}
                >
                  <Field label="Tag">
                    <input
                      className={inputClassName}
                      {...trendForm.register("tag")}
                      placeholder="#MonTag"
                    />
                    {trendForm.formState.errors.tag && (
                      <p className="mt-1 text-xs text-red-400">
                        {trendForm.formState.errors.tag.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Catégorie">
                    <Controller
                      name="category_slug"
                      control={trendForm.control}
                      render={({ field }) => (
                        <CategorySelect
                          value={field.value}
                          onChange={field.onChange}
                        />
                      )}
                    />
                  </Field>
                  <Field label="Ordre">
                    <input
                      className={inputClassName}
                      type="number"
                      {...trendForm.register("sort_order", {
                        valueAsNumber: true,
                      })}
                    />
                    {trendForm.formState.errors.sort_order && (
                      <p className="mt-1 text-xs text-red-400">
                        {trendForm.formState.errors.sort_order.message}
                      </p>
                    )}
                  </Field>
                  <SubmitButton
                    disabled={isBusy || !trendForm.formState.isValid}
                  >
                    Ajouter la tendance
                  </SubmitButton>
                </form>
              </AdminCard>

              {/* === Événement === */}
              <AdminCard title="Ajouter un événement">
                <form
                  className="space-y-4"
                  onSubmit={eventForm.handleSubmit((values) => {
                    runAction(async () => {
                      await createEvent(values);
                      eventForm.reset(initialEvent);
                    }, "Événement ajouté.");
                  })}
                >
                  <Field label="Titre">
                    <input
                      className={inputClassName}
                      {...eventForm.register("title")}
                    />
                    {eventForm.formState.errors.title && (
                      <p className="mt-1 text-xs text-red-400">
                        {eventForm.formState.errors.title.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Date label">
                    <input
                      className={inputClassName}
                      {...eventForm.register("date_label")}
                    />
                    {eventForm.formState.errors.date_label && (
                      <p className="mt-1 text-xs text-red-400">
                        {eventForm.formState.errors.date_label.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Catégorie">
                    <Controller
                      name="category_slug"
                      control={eventForm.control}
                      render={({ field }) => (
                        <CategorySelect
                          value={field.value}
                          onChange={field.onChange}
                        />
                      )}
                    />
                  </Field>
                  <Field label="Ordre">
                    <input
                      className={inputClassName}
                      type="number"
                      {...eventForm.register("sort_order", {
                        valueAsNumber: true,
                      })}
                    />
                    {eventForm.formState.errors.sort_order && (
                      <p className="mt-1 text-xs text-red-400">
                        {eventForm.formState.errors.sort_order.message}
                      </p>
                    )}
                  </Field>
                  <SubmitButton
                    disabled={isBusy || !eventForm.formState.isValid}
                  >
                    Ajouter l’événement
                  </SubmitButton>
                </form>
              </AdminCard>

              {/* === Statistique === */}
              <AdminCard title="Mettre à jour une statistique">
                <form
                  className="space-y-4"
                  onSubmit={statForm.handleSubmit((values) => {
                    runAction(async () => {
                      await upsertStat(values);
                      statForm.reset(initialStat);
                    }, "Statistique enregistrée.");
                  })}
                >
                  <Field label="Label">
                    <input
                      className={inputClassName}
                      {...statForm.register("label")}
                      placeholder="Artistes actifs"
                    />
                    {statForm.formState.errors.label && (
                      <p className="mt-1 text-xs text-red-400">
                        {statForm.formState.errors.label.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Valeur">
                    <input
                      className={inputClassName}
                      {...statForm.register("number_label")}
                    />
                    {statForm.formState.errors.number_label && (
                      <p className="mt-1 text-xs text-red-400">
                        {statForm.formState.errors.number_label.message}
                      </p>
                    )}
                  </Field>
                  <Field label="Ordre">
                    <input
                      className={inputClassName}
                      type="number"
                      {...statForm.register("sort_order", {
                        valueAsNumber: true,
                      })}
                    />
                    {statForm.formState.errors.sort_order && (
                      <p className="mt-1 text-xs text-red-400">
                        {statForm.formState.errors.sort_order.message}
                      </p>
                    )}
                  </Field>
                  <SubmitButton
                    disabled={isBusy || !statForm.formState.isValid}
                  >
                    Enregistrer la statistique
                  </SubmitButton>
                </form>
              </AdminCard>
            </div>
          </div>
        )}

        {flash ? <FlashBanner flash={flash} /> : null}
      </main>
    </div>
  );
}

const inputClassName =
  "w-full rounded-lg border border-border bg-background px-4 py-3 text-foreground outline-none transition-colors focus:border-primary";

function SetupPanel() {
  return (
    <div className="rounded-2xl border border-dashed border-border bg-card/60 p-10 text-center">
      <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-primary/10 text-primary">
        <LockKeyhole className="h-6 w-6" />
      </div>
      <h2 className="mb-3 text-3xl font-display italic text-foreground">
        Configuration Supabase requise
      </h2>
      <p className="mx-auto max-w-3xl text-muted-foreground">
        Ajoute `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY` dans `.env`,
        exécute `database/schema.sql`, puis recharge cette page.
      </p>
    </div>
  );
}

function AccessDeniedPanel({ email }: { email: string }) {
  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_1.1fr]">
      <div className="rounded-2xl border border-dashed border-border bg-card/60 p-10 text-center">
        <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-red-500/10 text-red-300">
          <ShieldAlert className="h-6 w-6" />
        </div>
        <h2 className="mb-3 text-3xl font-display italic text-foreground">
          Compte connecté mais non administrateur
        </h2>
        <p className="mx-auto max-w-3xl text-muted-foreground">
          Le compte <span className="font-medium text-foreground">{email}</span>{" "}
          existe bien, mais son rôle actuel n’autorise pas l’écriture dans la
          base.
        </p>
      </div>

      <div className="rounded-2xl border border-border bg-card/60 p-8 backdrop-blur">
        <h3 className="mb-4 text-2xl font-display text-foreground">
          Promotion en admin
        </h3>
        <p className="mb-4 text-sm text-muted-foreground">
          Dans le SQL Editor de Supabase, exécute cette commande pour promouvoir
          ce compte :
        </p>
        <pre className="overflow-x-auto rounded-xl border border-border bg-background p-4 text-sm text-primary">
          {`update public.profiles
set role = 'admin'
where email = '${email}';`}
        </pre>
        <p className="mt-4 text-sm text-muted-foreground">
          Recharge ensuite `admin.html` ou reconnecte-toi.
        </p>
      </div>
    </div>
  );
}

function InfoPanel({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-2xl border border-border bg-card/60 p-8 backdrop-blur">
      <h2 className="mb-3 text-3xl font-display italic text-foreground">
        {title}
      </h2>
      <p className="text-muted-foreground">{body}</p>
    </div>
  );
}

function AdminCard({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur">
      <h3 className="mb-5 text-2xl font-display text-foreground">{title}</h3>
      {children}
    </section>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block space-y-2 text-sm text-muted-foreground">
      <span>{label}</span>
      {children}
    </label>
  );
}

function CategorySelect({
  value,
  onChange,
}: {
  value: string;
  onChange: (value: string) => void;
}) {
  return (
    <select
      className={inputClassName}
      value={value}
      onChange={(event) => onChange(event.target.value)}
    >
      {categories.map((category) => (
        <option key={category.slug} value={category.slug}>
          {category.title}
        </option>
      ))}
    </select>
  );
}

function SubmitButton({
  children,
  disabled,
}: {
  children: React.ReactNode;
  disabled: boolean;
}) {
  return (
    <button
      type="submit"
      className="rounded-lg bg-primary px-5 py-3 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
      disabled={disabled}
    >
      {children}
    </button>
  );
}

function FlashBanner({
  flash,
}: {
  flash: Exclude<FlashMessage, null>;
}) {
  const styles =
    flash.type === "success"
      ? "border-primary/30 bg-primary/10 text-primary"
      : flash.type === "error"
        ? "border-red-500/30 bg-red-500/10 text-red-300"
        : "border-border bg-card/60 text-foreground";

  return (
    <div
      className={`fixed bottom-6 right-6 max-w-md rounded-xl border px-5 py-4 shadow-xl backdrop-blur ${styles}`}
    >
      {flash.text}
    </div>
  );
}
