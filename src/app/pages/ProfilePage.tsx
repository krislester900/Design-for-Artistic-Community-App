import { useEffect, useState } from "react";
import { getCurrentSession, type AuthUser } from "../services/auth";
import { supabase, hasSupabaseEnv } from "../lib/supabase";
import { ProfileBird } from "./ProfileBird";
import { getFavorites, type Favorite } from "../services/favorites";
import { ArtworkUploadForm } from "../profile/ArtworkUploadForm";

interface ProfilePageProps {
  user?: AuthUser;
}

type Tab = "profile" | "favorites" | "settings";

export default function ProfilePage({ user: initialUser }: ProfilePageProps) {
  const [user, setUser] = useState<AuthUser | null>(initialUser || null);
  const [loading, setLoading] = useState(!initialUser);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<Tab>("profile");

  const [displayName, setDisplayName] = useState("");
  const [bio, setBio] = useState("");
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [profileError, setProfileError] = useState<string | null>(null);
  const savedTimerRef = { current: null as ReturnType<typeof setTimeout> | null };

  const [visibilityFilter, setVisibilityFilter] = useState<string>("all");
  const [artworks, setArtworks] = useState<any[]>([]);
  const [favorites, setFavorites] = useState<Favorite[]>([]);
  const [artworksLoading, setArtworksLoading] = useState(false);

  useEffect(() => {
    return () => {
      if (savedTimerRef.current) clearTimeout(savedTimerRef.current);
    };
  }, []);

  useEffect(() => {
    if (!initialUser) {
      getCurrentSession().then(({ user, error }) => {
        if (error) setError(error.message);
        else if (user) {
          setUser(user);
          setDisplayName(user.user_metadata?.display_name ?? user.email?.split("@")[0] ?? "");
          setBio(user.user_metadata?.bio ?? "");
        }
        setLoading(false);
      });
    } else {
      setUser(initialUser);
      setDisplayName(initialUser.user_metadata?.display_name ?? initialUser.email?.split("@")[0] ?? "");
      setBio(initialUser.user_metadata?.bio ?? "");
      setLoading(false);
    }
  }, [initialUser]);

  useEffect(() => {
    if (!user) return;
    getFavorites().then(setFavorites);
  }, [user, tab]);

  const loadArtworks = async () => {
    setArtworksLoading(true);
    try {
      const res = await fetch("/api/artworks?author=" + encodeURIComponent(user?.email ?? ""));
      const data = await res.json();
      const list = Array.isArray(data) ? data : [];
      setArtworks(list.filter((art: any) => {
        const v = art.visibility ?? "public";
        if (v === "public") return true;
        if (v === "subscribers") return true;
        if (v === "private") return false;
        return true;
      }));
    } catch {
      setArtworks([]);
    } finally {
      setArtworksLoading(false);
    }
  };

  useEffect(() => {
    if (tab === "favorites") {
      getFavorites().then(setFavorites);
    }
    if (tab === "profile") {
      loadArtworks();
    }
  }, [tab]);

  async function handleSaveProfile() {
    setSaving(true);
    setProfileError(null);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Non connecté");

      const { error } = await supabase.auth.updateUser({
        data: {
          display_name: displayName,
          bio: bio,
        },
      });

      if (error) throw error;

      setSaved(true);
      if (savedTimerRef.current) clearTimeout(savedTimerRef.current);
      savedTimerRef.current = setTimeout(() => setSaved(false), 2000);
    } catch (e) {
      setProfileError(e instanceof Error ? e.message : "Erreur inconnue");
    } finally {
      setSaving(false);
    }
  }

  async function handleLogout() {
    await fetch("/api/auth/logout", { method: "POST" });
    window.location.href = "/";
  }

  if (loading) return <div className="loading">Chargement du profil...</div>;
  if (error) return <div className="error">Erreur : {error}</div>;
  if (!user) {
    return (
      <div className="px-6 py-20">
        <div className="street-panel mx-auto max-w-2xl p-10 text-center">
          <h2 className="street-title mb-4 text-3xl">Connexion requise</h2>
          <p className="text-muted-foreground">
            Connecte-toi pour accéder à ton profil, gérer tes favoris et publier du contenu.
          </p>
          <a href="/login" className="mt-6 inline-block rounded-xl border border-primary/30 bg-primary px-6 py-3 text-sm font-semibold uppercase tracking-[0.18em] text-primary-foreground">
            Se connecter
          </a>
        </div>
      </div>
    );
  }

  const visibleArtworks =
    visibilityFilter === "all" ? artworks : artworks.filter((art) => art.visibility === visibilityFilter);

  const tabs: { id: Tab; label: string; icon: string }[] = [
    { id: "profile", label: "Profil", icon: "👤" },
    { id: "favorites", label: "Favoris", icon: "❤️" },
    { id: "settings", label: "Paramètres", icon: "⚙️" },
  ];

  return (
    <div className="px-6 py-10">
      <div className="mx-auto max-w-4xl">
        <div className="street-panel mb-8 p-8">
          <div className="flex flex-col items-center gap-6 md:flex-row md:items-start">
            <div className="relative">
              <div className="flex h-24 w-24 items-center justify-center rounded-full border-2 border-primary/30 bg-gradient-to-br from-primary/20 to-accent/20 text-2xl font-bold text-primary">
                {user.user_metadata?.avatar_url ? (
                  <img src={user.user_metadata.avatar_url} alt="Avatar" className="h-full w-full rounded-full object-cover" />
                ) : (
                  displayName.charAt(0).toUpperCase()
                )}
              </div>
            </div>

            <div className="flex-1 text-center md:text-left">
              <h1 className="street-title text-3xl">{displayName || user.email}</h1>
              <p className="mt-1 text-sm text-muted-foreground">{user.email}</p>
              {bio && <p className="mt-3 text-muted-foreground">{bio}</p>}
              <div className="mt-4 flex flex-wrap justify-center gap-4 md:justify-start">
                <span className="text-sm">
                  <strong className="text-foreground">{favorites.length}</strong> <span className="text-muted-foreground">favoris</span>
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="mb-6 flex gap-2 overflow-x-auto">
          {tabs.map((item) => (
            <button
              key={item.id}
              onClick={() => setTab(item.id)}
              className={`flex items-center gap-2 rounded-xl border px-4 py-2.5 text-xs font-semibold uppercase tracking-[0.16em] transition-colors whitespace-nowrap ${
                tab === item.id ? "border-primary bg-primary/10 text-primary" : "border-border bg-card/40 text-muted-foreground hover:border-primary hover:text-primary"
              }`}
            >
              <span>{item.icon}</span>
              {item.label}
            </button>
          ))}
        </div>

        {tab === "profile" && (
          <div className="street-panel space-y-6 p-8">
            <h2 className="street-title text-2xl">Modifier le profil</h2>

            <div>
              <label className="mb-2 block text-xs uppercase tracking-[0.2em] text-muted-foreground">Nom créatif</label>
              <input
                className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground/50 focus:border-primary"
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                placeholder="Ton nom créatif"
              />
            </div>

            <div>
              <label className="mb-2 block text-xs uppercase tracking-[0.2em] text-muted-foreground">Bio</label>
              <textarea
                className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground/50 focus:border-primary min-h-[100px] resize-y"
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                placeholder="Parle de toi, de ton art, de ton univers..."
              />
            </div>

            {profileError && <p className="text-sm text-red-300">{profileError}</p>}

            <div className="flex gap-3">
              <button
                onClick={handleSaveProfile}
                disabled={saving}
                className="flex items-center gap-2 rounded-xl border border-primary/30 bg-primary px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-primary-foreground shadow-[0_10px_30px_rgba(255,106,26,0.25)] transition-all hover:-translate-y-0.5"
              >
                {saving ? "Enregistrement..." : saved ? "✓ Enregistré" : "Enregistrer"}
              </button>
            </div>

            <div>
              <h3 className="mb-4 text-lg font-semibold text-foreground">Publier une création</h3>
              <ArtworkUploadForm onUploaded={loadArtworks} authorName={displayName} authorEmail={user.email} />
            </div>
          </div>
        )}

        {tab === "favorites" && (
          <div className="street-panel p-8">
            <h2 className="street-title mb-6 text-2xl">Mes favoris</h2>
            <FavoritesList favs={favorites} />
          </div>
        )}

        {tab === "settings" && (
          <div className="space-y-6">
            <div className="street-panel p-8">
              <h2 className="street-title mb-6 text-2xl">Paramètres du compte</h2>
              <div className="space-y-4">
                <div className="flex items-center justify-between rounded-xl border border-border p-4">
                  <div>
                    <p className="font-medium text-foreground">Email</p>
                    <p className="text-sm text-muted-foreground">{user.email}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between rounded-xl border border-border p-4">
                  <div>
                    <p className="font-medium text-foreground">Membre depuis</p>
                    <p className="text-sm text-muted-foreground">
                      {new Date(user.created_at).toLocaleDateString("fr-FR")}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div className="street-panel border-red-500/20 p-8">
              <h3 className="street-title mb-4 text-xl text-red-400">Zone de danger</h3>
              <button
                onClick={handleLogout}
                className="flex items-center gap-2 rounded-xl border border-red-500/30 bg-red-500/10 px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-red-400 transition-colors hover:bg-red-500/20"
              >
                Se déconnecter
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function FavoritesList({ favs }: { favs: Favorite[] }) {
  if (favs.length === 0) {
    return <p className="text-muted-foreground">Tu n'as pas encore de favoris. Explore les œuvres et ajoute-les à tes favoris !</p>;
  }

  return (
    <div className="grid grid-cols-2 gap-4 md:grid-cols-3">
      {favs.map((fav) => (
        <div key={fav.id} className="rounded-xl border border-border bg-card/60 p-4">
          <div className="text-sm font-medium text-foreground">{fav.target_id ?? "Sans titre"}</div>
          <div className="text-xs text-muted-foreground">{fav.target_type ?? "Général"}</div>
        </div>
      ))}
    </div>
  );
}
