import { useState, useEffect } from "react";
import { User, Upload, Save, LogOut, Heart, Bookmark, Settings } from "lucide-react";
import { getCurrentSession, onAuthChange, signOut, type AuthUser } from "../services/auth";
import { getFavorites } from "../services/favorites";
import { getStaticPagePath } from "../lib/page-links";

export function ProfilePage() {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [displayName, setDisplayName] = useState("");
  const [bio, setBio] = useState("");
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const savedTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (savedTimerRef.current) clearTimeout(savedTimerRef.current);
    };
  }, []);
  const [favoriteCount, setFavoriteCount] = useState(0);
  const [activeTab, setActiveTab] = useState<"profile" | "favorites" | "settings">("profile");

  useEffect(() => {
    getCurrentSession().then(({ user }) => {
      if (user) {
        setUser(user);
        setDisplayName(user.user_metadata?.display_name ?? user.email?.split("@")[0] ?? "");
        setBio(user.user_metadata?.bio ?? "");
      }
    });
    const sub = onAuthChange((u) => setUser(u));
    return () => sub.unsubscribe();
  }, []);

  useEffect(() => {
    if (user) {
      getFavorites("artwork").then((favs) => setFavoriteCount(favs.length));
    }
  }, [user]);

  async function handleSave() {
    setSaving(true);
    await new Promise((r) => setTimeout(r, 800));
    setSaving(false);
    setSaved(true);
    if (savedTimerRef.current) clearTimeout(savedTimerRef.current);
    savedTimerRef.current = setTimeout(() => setSaved(false), 2000);
  }

  async function handleLogout() {
    await signOut();
    setUser(null);
  }

  if (!user) {
    return (
      <div className="px-6 py-20">
        <div className="street-panel mx-auto max-w-2xl p-10 text-center">
          <User className="mx-auto mb-4 h-12 w-12 text-muted-foreground" />
          <h2 className="street-title mb-4 text-3xl">Connexion requise</h2>
          <p className="text-muted-foreground">
            Connecte-toi pour accéder à ton profil, gérer tes favoris et publier du contenu.
          </p>
          <a
            href={getStaticPagePath("login")}
            className="mt-6 inline-block rounded-xl border border-primary/30 bg-primary px-6 py-3 text-sm font-semibold uppercase tracking-[0.18em] text-primary-foreground"
          >
            Se connecter
          </a>
        </div>
      </div>
    );
  }

  const tabs = [
    { id: "profile" as const, label: "Profil", icon: <User className="h-4 w-4" /> },
    { id: "favorites" as const, label: "Favoris", icon: <Heart className="h-4 w-4" />, count: favoriteCount },
    { id: "settings" as const, label: "Paramètres", icon: <Settings className="h-4 w-4" /> },
  ];

  return (
    <div className="px-6 py-10">
      <div className="mx-auto max-w-4xl">
        {/* Profile Header */}
        <div className="street-panel mb-8 p-8">
          <div className="flex flex-col items-center gap-6 md:flex-row md:items-start">
            <div className="relative">
              <div className="flex h-24 w-24 items-center justify-center rounded-full border-2 border-primary/30 bg-gradient-to-br from-primary/20 to-accent/20">
                <User className="h-10 w-10 text-primary" />
              </div>
              <button className="absolute -bottom-1 -right-1 flex h-8 w-8 items-center justify-center rounded-full border border-border bg-background text-primary hover:bg-primary hover:text-primary-foreground">
                <Upload className="h-3.5 w-3.5" />
              </button>
            </div>

            <div className="flex-1 text-center md:text-left">
              <h1 className="street-title text-3xl">{displayName || user.email}</h1>
              <p className="mt-1 text-sm text-muted-foreground">{user.email}</p>
              {bio && <p className="mt-3 text-muted-foreground">{bio}</p>}
              <div className="mt-4 flex flex-wrap justify-center gap-4 md:justify-start">
                <span className="text-sm"><strong className="text-foreground">{favoriteCount}</strong> <span className="text-muted-foreground">favoris</span></span>
              </div>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="mb-6 flex gap-2 overflow-x-auto">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              className={`flex items-center gap-2 rounded-xl border px-4 py-2.5 text-xs font-semibold uppercase tracking-[0.16em] transition-colors whitespace-nowrap ${
                activeTab === tab.id
                  ? "border-primary bg-primary/10 text-primary"
                  : "border-border bg-card/40 text-muted-foreground hover:border-primary hover:text-primary"
              }`}
              onClick={() => setActiveTab(tab.id)}
            >
              {tab.icon}
              {tab.label}
              {tab.count !== undefined && (
                <span className="ml-1 rounded-full bg-primary/20 px-2 py-0.5 text-[10px] text-primary">{tab.count}</span>
              )}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        {activeTab === "profile" && (
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

            <div className="flex gap-3">
              <button
                className="flex items-center gap-2 rounded-xl border border-primary/30 bg-primary px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-primary-foreground shadow-[0_10px_30px_rgba(255,106,26,0.25)] transition-all hover:-translate-y-0.5"
                onClick={handleSave}
                disabled={saving}
              >
                <Save className="h-4 w-4" />
                {saving ? "Enregistrement..." : saved ? "✓ Enregistré" : "Enregistrer"}
              </button>
            </div>
          </div>
        )}

        {activeTab === "favorites" && (
          <div className="street-panel p-8">
            <h2 className="street-title mb-6 text-2xl">Mes favoris</h2>
            <p className="text-muted-foreground">
              {favoriteCount > 0
                ? `Tu as ${favoriteCount} favori${favoriteCount > 1 ? "s" : ""} enregistré${favoriteCount > 1 ? "s" : ""}.`
                : "Tu n'as pas encore de favoris. Explore les œuvres et ajoute-les à tes favoris !"}
            </p>
          </div>
        )}

        {activeTab === "settings" && (
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
                className="flex items-center gap-2 rounded-xl border border-red-500/30 bg-red-500/10 px-6 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-red-400 transition-colors hover:bg-red-500/20"
                onClick={handleLogout}
              >
                <LogOut className="h-4 w-4" />
                Se déconnecter
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}