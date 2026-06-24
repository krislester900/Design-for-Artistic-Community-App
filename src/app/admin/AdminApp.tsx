import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  artistSchema,
  artworkSchema,
  discussionSchema,
  loginSchema,
  type ArtistForm,
  type ArtworkForm,
  type DiscussionForm,
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

const initialArtist = {
  name: "",
  category_slug: "music",
  role: "",
  image: "",
  featured_work: "",
};

const initialArtwork = {
  title: "",
  artist_name: "",
  category_slug: "music",
  medium: "",
  image: "",
  height: "aspect-square",
};

const initialDiscussion = {
  title: "",
  author_name: "",
  category_slug: "music",
  time_label: "Aujourd’hui",
  trending: false,
};

const initialTrend = {
  tag: "",
  category_slug: "music",
  sort_order: 1,
};

const initialEvent = {
  title: "",
  date_label: "",
  category_slug: "music",
  sort_order: 1,
};

const initialStat = {
  label: "",
  number_label: "0",
  sort_order: 1,
};

type FlashMessage = {
  type: "success" | "error" | "info";
  text: string;
} | null;

export function AdminApp() {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<AdminProfile | null>(null);
  const [isBooting, setIsBooting] = useState(true);
  const [isBusy, setIsBusy] = useState(false);
  const [flash, setFlash] = useState<FlashMessage>(null);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

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

  const [trendForm, setTrendForm] = useState(initialTrend);
  const [eventForm, setEventForm] = useState(initialEvent);
  const [statForm, setStatForm] = useState(initialStat);

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

  async function runAction(action: () => Promise<void>, successText: string) {
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
              <h1 className="text-2xl italic tracking-wide text-primary" style={{ fontFamily: "'Alien Block', cursive" }}>
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
                    "Connexion réussie.",
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
                    <p className="mt-1 text-xs text-red-400">{loginForm.formState.errors.email.message}</p>
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
                    <p className="mt-1 text-xs text-red-400">{loginForm.formState.errors.password.message}</p>
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
                          "Compte créé. Il devra ensuite être promu au rôle admin dans Supabase.",
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
            email={profile?.email ?? session.user.email ?? email}
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
                      "Catégories synchronisées avec succès.",
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
                      <p className="mt-1 text-xs text-red-400">{artistForm.formState.errors.name.message}</p>
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
                      <p className="mt-1 text-xs text-red-400">{artistForm.formState.errors.role.message}</p>
                    )}
                  </Field>
                  <Field label="Image URL">
                    <input
                      className={inputClassName}
                      {...artistForm.register("image")}
                    />
                    {artistForm.formState.errors.image && (
                      <p className="mt-1 text-xs text-red-400">{artistForm.formState.errors.image.message}</p>
                    )}
                  </Field>
                  <Field label="Œuvre mise en avant">
                    <input
                      className={inputClassName}
                      {...artistForm.register("featured_work")}
                    />
                    {artistForm.formState.errors.featured_work && (
                      <p className="mt-1 text-xs text-red-400">{artistForm.formState.errors.featured_work.message}</p>
                    )}
                  </Field>
                  <SubmitButton disabled={isBusy || !artistForm.formState.isValid}>
                    Ajouter l’artiste
                  </SubmitButton>
                </form>
              </AdminCard>

              <AdminCard title="Ajouter une œuvre">
                <form
                  className="space-y-4"
                  onSubmit={(event) => {
                    event.preventDefault();
                    runAction(async () => {
                      await createArtwork(artworkForm);
                      setArtworkForm(initialArtwork);
                    }, "Œuvre ajoutée.");
                  }}
                >
                  <Field label="Titre">
                    <input
                      className={inputClassName}
                      value={artworkForm.title}
                      onChange={(e) =>
                        setArtworkForm({
                          ...artworkForm,
                          title: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <Field label="Nom de l’artiste">
                    <input
                      className={inputClassName}
                      value={artworkForm.artist_name}
                      onChange={(e) =>
                        setArtworkForm({
                          ...artworkForm,
                          artist_name: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <Field label="Catégorie">
                    <CategorySelect
                      value={artworkForm.category_slug}
                      onChange={(value) =>
                        setArtworkForm({ ...artworkForm, category_slug: value })
                      }
                    />
                  </Field>
                  <Field label="Medium">
                    <input
                      className={inputClassName}
                      value={artworkForm.medium}
                      onChange={(e) =>
                        setArtworkForm({
                          ...artworkForm,
                          medium: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <Field label="Image URL">
                    <input
                      className={inputClassName}
                      value={artworkForm.image}
                      onChange={(e) =>
                        setArtworkForm({
                          ...artworkForm,
                          image: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <Field label="Format">
                    <input
                      className={inputClassName}
                      value={artworkForm.height}
                      onChange={(e) =>
                        setArtworkForm({
                          ...artworkForm,
                          height: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <SubmitButton disabled={isBusy}>Ajouter l’œuvre</SubmitButton>
                </form>
              </AdminCard>

              <AdminCard title="Ajouter une discussion">
                <form
                  className="space-y-4"
                  onSubmit={(event) => {
                    event.preventDefault();
                    runAction(async () => {
                      await createDiscussion(discussionForm);
                      setDiscussionForm(initialDiscussion);
                    }, "Discussion ajoutée.");
                  }}
                >
                  <Field label="Titre">
                    <input
                      className={inputClassName}
                      value={discussionForm.title}
                      onChange={(e) =>
                        setDiscussionForm({
                          ...discussionForm,
                          title: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <Field label="Auteur">
                    <input
                      className={inputClassName}
                      value={discussionForm.author_name}
                      onChange={(e) =>
                        setDiscussionForm({
                          ...discussionForm,
                          author_name: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <Field label="Catégorie">
                    <CategorySelect
                      value={discussionForm.category_slug}
                      onChange={(value) =>
                        setDiscussionForm({
                          ...discussionForm,
                          category_slug: value,
                        })
                      }
                    />
                  </Field>
                  <Field label="Label temps">
                    <input
                      className={inputClassName}
                      value={discussionForm.time_label}
                      onChange={(e) =>
                        setDiscussionForm({
                          ...discussionForm,
                          time_label: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <label className="flex items-center gap-3 text-sm text-muted-foreground">
                    <input
                      type="checkbox"
                      checked={discussionForm.trending}
                      onChange={(e) =>
                        setDiscussionForm({
                          ...discussionForm,
                          trending: e.target.checked,
                        })
                      }
                    />
                    Marquer comme tendance
                  </label>
                  <SubmitButton disabled={isBusy}>
                    Ajouter la discussion
                  </SubmitButton>
                </form>
              </AdminCard>

              <AdminCard title="Ajouter une tendance">
                <form
                  className="space-y-4"
                  onSubmit={(event) => {
                    event.preventDefault();
                    runAction(async () => {
                      await createTrend(trendForm);
                      setTrendForm(initialTrend);
                    }, "Tendance ajoutée.");
                  }}
                >
                  <Field label="Tag">
                    <input
                      className={inputClassName}
                      value={trendForm.tag}
                      onChange={(e) =>
                        setTrendForm({ ...trendForm, tag: e.target.value })
                      }
                      placeholder="#MonTag"
                      required
                    />
                  </Field>
                  <Field label="Catégorie">
                    <CategorySelect
                      value={trendForm.category_slug}
                      onChange={(value) =>
                        setTrendForm({ ...trendForm, category_slug: value })
                      }
                    />
                  </Field>
                  <Field label="Ordre">
                    <input
                      className={inputClassName}
                      type="number"
                      value={trendForm.sort_order}
                      onChange={(e) =>
                        setTrendForm({
                          ...trendForm,
                          sort_order: Number(e.target.value),
                        })
                      }
                      required
                    />
                  </Field>
                  <SubmitButton disabled={isBusy}>
                    Ajouter la tendance
                  </SubmitButton>
                </form>
              </AdminCard>

              <AdminCard title="Ajouter un événement">
                <form
                  className="space-y-4"
                  onSubmit={(event) => {
                    event.preventDefault();
                    runAction(async () => {
                      await createEvent(eventForm);
                      setEventForm(initialEvent);
                    }, "Événement ajouté.");
                  }}
                >
                  <Field label="Titre">
                    <input
                      className={inputClassName}
                      value={eventForm.title}
                      onChange={(e) =>
                        setEventForm({ ...eventForm, title: e.target.value })
                      }
                      required
                    />
                  </Field>
                  <Field label="Date label">
                    <input
                      className={inputClassName}
                      value={eventForm.date_label}
                      onChange={(e) =>
                        setEventForm({
                          ...eventForm,
                          date_label: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <Field label="Catégorie">
                    <CategorySelect
                      value={eventForm.category_slug}
                      onChange={(value) =>
                        setEventForm({ ...eventForm, category_slug: value })
                      }
                    />
                  </Field>
                  <Field label="Ordre">
                    <input
                      className={inputClassName}
                      type="number"
                      value={eventForm.sort_order}
                      onChange={(e) =>
                        setEventForm({
                          ...eventForm,
                          sort_order: Number(e.target.value),
                        })
                      }
                      required
                    />
                  </Field>
                  <SubmitButton disabled={isBusy}>
                    Ajouter l’événement
                  </SubmitButton>
                </form>
              </AdminCard>

              <AdminCard title="Mettre à jour une statistique">
                <form
                  className="space-y-4"
                  onSubmit={(event) => {
                    event.preventDefault();
                    runAction(async () => {
                      await upsertStat(statForm);
                      setStatForm(initialStat);
                    }, "Statistique enregistrée.");
                  }}
                >
                  <Field label="Label">
                    <input
                      className={inputClassName}
                      value={statForm.label}
                      onChange={(e) =>
                        setStatForm({ ...statForm, label: e.target.value })
                      }
                      placeholder="Artistes actifs"
                      required
                    />
                  </Field>
                  <Field label="Valeur">
                    <input
                      className={inputClassName}
                      value={statForm.number_label}
                      onChange={(e) =>
                        setStatForm({
                          ...statForm,
                          number_label: e.target.value,
                        })
                      }
                      required
                    />
                  </Field>
                  <Field label="Ordre">
                    <input
                      className={inputClassName}
                      type="number"
                      value={statForm.sort_order}
                      onChange={(e) =>
                        setStatForm({
                          ...statForm,
                          sort_order: Number(e.target.value),
                        })
                      }
                      required
                    />
                  </Field>
                  <SubmitButton disabled={isBusy}>
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

function FlashBanner({ flash }: { flash: Exclude<FlashMessage, null> }) {
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
