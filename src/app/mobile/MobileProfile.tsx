/**
 * MobileProfile — Profil complexe avec stats, galerie, activité, paramètres
 */
import { useState, useEffect } from "react";
import { 
  User, Settings, LogOut, Heart, Palette, Bookmark, Bell, ChevronRight, 
  Camera, Edit3, Share2, Grid3X3, List, Clock, Star, Trophy, Flame,
  Image, Music, Film, BookOpen, Clapperboard, Pen, TrendingUp,
  Moon, Sun, Globe, Shield, HelpCircle, MessageCircle, Users,
  ChevronDown, ExternalLink, Copy, Check, Plus, Eye
} from "lucide-react";
import { signIn, signUp, signInWithGoogle, signOut as doSignOut, getCurrentSession, onAuthChange, type AuthUser } from "../services/auth";
import { hasSupabaseEnv } from "../lib/supabase";

interface MenuItem {
  icon: typeof Heart;
  label: string;
  color: string;
  badge?: number;
  action?: () => void;
}

interface GalleryItem {
  id: string;
  title: string;
  category: string;
  emoji: string;
  likes: number;
  views: number;
  gradient: string;
}

interface ActivityItem {
  id: string;
  type: "like" | "comment" | "follow" | "publish";
  user: string;
  content: string;
  time: string;
  emoji: string;
}

const GALLERY_ITEMS: GalleryItem[] = [
  { id: "1", title: "Portrait Neon", category: "Art Visuel", emoji: "🎨", likes: 234, views: 1200, gradient: "from-orange-500 to-red-500" },
  { id: "2", title: "Beat Session", category: "Musique", emoji: "🎵", likes: 189, views: 890, gradient: "from-violet-500 to-purple-500" },
  { id: "3", title: "Manga Panel", category: "Manga", emoji: "📚", likes: 312, views: 1560, gradient: "from-blue-500 to-cyan-500" },
  { id: "4", title: "Court-Métrage", category: "Films", emoji: "🎬", likes: 156, views: 780, gradient: "from-emerald-500 to-teal-500" },
  { id: "5", title: "Poème Urbain", category: "Littérature", emoji: "✍️", likes: 98, views: 450, gradient: "from-rose-500 to-pink-500" },
  { id: "6", title: "Motion Loop", category: "Animation", emoji: "🎞️", likes: 267, views: 1340, gradient: "from-cyan-500 to-blue-500" },
];

const ACTIVITY_ITEMS: ActivityItem[] = [
  { id: "1", type: "like", user: "ArtDiva", content: "a aimé Portrait Neon", time: "Il y a 2h", emoji: "❤️" },
  { id: "2", type: "comment", user: "MusicPro", content: "a commenté Beat Session", time: "Il y a 4h", emoji: "💬" },
  { id: "3", type: "follow", user: "MangaKing", content: "te suit", time: "Il y a 6h", emoji: "👤" },
  { id: "4", type: "publish", user: "Toi", content: "as publié Motion Loop", time: "Il y a 1j", emoji: "✨" },
  { id: "5", type: "like", user: "FilmArt", content: "a aimé Court-Métrage", time: "Il y a 2j", emoji: "❤️" },
];

export function MobileProfile() {
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [showAuth, setShowAuth] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showGallery, setShowGallery] = useState<"grid" | "list">("grid");
  const [activeTab, setActiveTab] = useState<"gallery" | "activity" | "stats">("gallery");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState("");
  const [darkMode, setDarkMode] = useState(true);
  const [notifications, setNotifications] = useState(true);
  const [language, setLanguage] = useState("Français");

  useEffect(() => {
    getCurrentSession().then(({ user }) => { if (user) setAuthUser(user); });
    const sub = onAuthChange((u) => setAuthUser(u));
    return () => sub.unsubscribe();
  }, []);

  async function handleSignIn(e: React.FormEvent) {
    e.preventDefault();
    setIsSubmitting(true);
    setMessage("");
    const { error } = await signIn(email, password);
    if (error) setMessage(error);
    setIsSubmitting(false);
  }

  async function handleSignUp(e: React.FormEvent) {
    e.preventDefault();
    setIsSubmitting(true);
    setMessage("");
    const { error } = await signUp(email, password);
    if (error) setMessage(error);
    else setMessage("Compte créé ! Vérifie tes emails.");
    setIsSubmitting(false);
  }

  async function handleGoogleSignIn() {
    setMessage("");
    const { error } = await signInWithGoogle();
    if (error) setMessage(error);
  }

  async function handleLogout() {
    await doSignOut();
    setAuthUser(null);
  }

  // Settings view
  if (showSettings) {
    return (
      <div className="px-4 py-6 space-y-6 pb-24">
        <div className="flex items-center gap-3">
          <button onClick={() => setShowSettings(false)} className="text-primary text-sm font-medium touch-manipulation">
            ← Retour
          </button>
          <h1 className="text-xl font-bold text-foreground" style={{ fontFamily: "'Outfit', sans-serif" }}>Paramètres</h1>
        </div>

        {/* Theme */}
        <div className="rounded-2xl bg-card/60 border border-border/30 overflow-hidden divide-y divide-border/20">
          <div className="flex items-center justify-between p-4">
            <div className="flex items-center gap-3">
              {darkMode ? <Moon className="h-5 w-5 text-primary" /> : <Sun className="h-5 w-5 text-amber-400" />}
              <span className="text-sm font-medium text-foreground">Mode sombre</span>
            </div>
            <button
              onClick={() => setDarkMode(!darkMode)}
              className={`relative h-6 w-11 rounded-full transition-colors duration-200 ${darkMode ? "bg-primary" : "bg-muted"}`}
            >
              <div className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform duration-200 ${darkMode ? "translate-x-5" : "translate-x-0.5"}`} />
            </button>
          </div>

          <div className="flex items-center justify-between p-4">
            <div className="flex items-center gap-3">
              <Bell className="h-5 w-5 text-cyan-400" />
              <span className="text-sm font-medium text-foreground">Notifications</span>
            </div>
            <button
              onClick={() => setNotifications(!notifications)}
              className={`relative h-6 w-11 rounded-full transition-colors duration-200 ${notifications ? "bg-primary" : "bg-muted"}`}
            >
              <div className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform duration-200 ${notifications ? "translate-x-5" : "translate-x-0.5"}`} />
            </button>
          </div>

          <button className="flex items-center justify-between p-4 w-full active:bg-card/60 transition-colors">
            <div className="flex items-center gap-3">
              <Globe className="h-5 w-5 text-green-400" />
              <span className="text-sm font-medium text-foreground">Langue</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-xs text-muted-foreground">{language}</span>
              <ChevronRight className="h-4 w-4 text-muted-foreground/30" />
            </div>
          </button>
        </div>

        {/* Account */}
        <div className="rounded-2xl bg-card/60 border border-border/30 overflow-hidden divide-y divide-border/20">
          <button className="flex items-center justify-between p-4 w-full active:bg-card/60 transition-colors">
            <div className="flex items-center gap-3">
              <Shield className="h-5 w-5 text-primary" />
              <span className="text-sm font-medium text-foreground">Confidentialité</span>
            </div>
            <ChevronRight className="h-4 w-4 text-muted-foreground/30" />
          </button>

          <button className="flex items-center justify-between p-4 w-full active:bg-card/60 transition-colors">
            <div className="flex items-center gap-3">
              <HelpCircle className="h-5 w-5 text-amber-400" />
              <span className="text-sm font-medium text-foreground">Aide & Support</span>
            </div>
            <ChevronRight className="h-4 w-4 text-muted-foreground/30" />
          </button>

          <button className="flex items-center justify-between p-4 w-full active:bg-card/60 transition-colors">
            <div className="flex items-center gap-3">
              <ExternalLink className="h-5 w-5 text-cyan-400" />
              <span className="text-sm font-medium text-foreground">Conditions d'utilisation</span>
            </div>
            <ChevronRight className="h-4 w-4 text-muted-foreground/30" />
          </button>
        </div>

        <div className="p-3 rounded-xl bg-card/40 border border-border/30 text-center">
          <p className="text-[10px] text-muted-foreground/50 uppercase tracking-[0.2em]">Artéïa v1.0.0</p>
        </div>
      </div>
    );
  }

  // Auth form view
  if (showAuth && !authUser) {
    return (
      <div className="px-4 py-6 pb-24">
        <button onClick={() => setShowAuth(false)} className="text-primary text-sm font-medium mb-6 touch-manipulation">
          ← Retour au profil
        </button>
        <h2 className="text-xl font-bold text-foreground mb-6" style={{ fontFamily: "'Outfit', sans-serif" }}>Connexion</h2>

        {message && (
          <div className="rounded-xl bg-primary/10 border border-primary/20 p-3 mb-4 text-xs text-primary leading-relaxed">
            {message}
          </div>
        )}

        {hasSupabaseEnv && (
          <button
            onClick={handleGoogleSignIn}
            className="flex items-center justify-center gap-2 w-full rounded-xl border border-border bg-card/60 p-3 text-sm font-medium text-foreground active:scale-95 transition-all touch-manipulation mb-3 hover:border-primary/30"
          >
            <svg className="h-5 w-5" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            Continuer avec Google
          </button>
        )}

        {hasSupabaseEnv && (
          <div className="flex items-center gap-3 mb-3">
            <div className="flex-1 border-t border-border/40" />
            <span className="text-[10px] uppercase tracking-[0.2em] text-muted-foreground/40">ou</span>
            <div className="flex-1 border-t border-border/40" />
          </div>
        )}

        <form onSubmit={handleSignIn} className="space-y-3">
          <input
            className="w-full h-11 rounded-xl border border-border/50 bg-card/60 px-3 text-sm text-foreground outline-none focus:border-primary/50 focus:ring-2 focus:ring-primary/5 placeholder:text-muted-foreground/30"
            type="email" placeholder="Email" value={email}
            onChange={(e) => setEmail(e.target.value)} required
          />
          <input
            className="w-full h-11 rounded-xl border border-border/50 bg-card/60 px-3 text-sm text-foreground outline-none focus:border-primary/50 focus:ring-2 focus:ring-primary/5 placeholder:text-muted-foreground/30"
            type="password" placeholder="Mot de passe" value={password}
            onChange={(e) => setPassword(e.target.value)} required minLength={6}
          />
          <button
            disabled={isSubmitting || !hasSupabaseEnv}
            className="w-full h-12 rounded-xl bg-gradient-to-r from-primary to-accent text-primary-foreground font-semibold text-sm active:scale-95 transition-all touch-manipulation shadow-lg shadow-primary/20 disabled:opacity-40"
            type="submit"
          >
            {isSubmitting ? "Connexion..." : "Se connecter"}
          </button>
          <button onClick={handleSignUp} type="button" className="w-full h-10 rounded-xl text-sm text-primary font-medium active:scale-95 touch-manipulation">
            Créer un compte
          </button>
        </form>
      </div>
    );
  }

  // Logged-out profile view
  if (!authUser) {
    return (
      <div className="px-4 py-6 space-y-6 pb-24">
        <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-primary/10 via-background to-accent/5 border border-border/30 p-6 text-center">
          <div className="relative mx-auto mb-4 h-20 w-20 flex items-center justify-center rounded-full bg-gradient-to-br from-primary to-accent shadow-xl shadow-primary/20">
            <User className="h-9 w-9 text-primary-foreground" />
          </div>
          <h1 className="text-xl font-bold text-foreground" style={{ fontFamily: "'Outfit', sans-serif" }}>Invité</h1>
          <p className="text-xs text-muted-foreground mt-1">Connecte-toi pour commencer à créer</p>
          <button
            onClick={() => setShowAuth(true)}
            className="mt-5 w-full h-11 rounded-xl bg-gradient-to-r from-primary to-accent text-primary-foreground font-semibold text-sm active:scale-95 transition-all touch-manipulation shadow-lg shadow-primary/20"
          >
            Se connecter
          </button>
        </div>

        <div className="p-3 rounded-xl bg-card/40 border border-border/30 text-center">
          <p className="text-[10px] text-muted-foreground/50 uppercase tracking-[0.2em]">Artéïa v1.0.0</p>
        </div>
      </div>
    );
  }

  // Logged-in profile view
  return (
    <div className="px-4 py-6 space-y-6 pb-24">
      {/* Profile Header Card */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-primary/10 via-background to-accent/5 border border-border/30 p-6">
        <div className="absolute -top-10 -right-10 h-24 w-24 rounded-full bg-primary/15 blur-2xl" />
        <div className="absolute -bottom-8 -left-8 h-20 w-20 rounded-full bg-accent/10 blur-2xl" />

        <div className="relative flex items-start gap-4">
          <div className="relative">
            <div className="h-20 w-20 rounded-full bg-gradient-to-br from-primary via-primary to-accent p-[3px] shadow-xl shadow-primary/20">
              <div className="flex h-full w-full items-center justify-center rounded-full bg-background">
                <span className="text-2xl font-bold text-primary">
                  {authUser.display_name?.charAt(0) || authUser.email?.charAt(0)?.toUpperCase() || "C"}
                </span>
              </div>
            </div>
            <button className="absolute -bottom-1 -right-1 h-7 w-7 rounded-full bg-primary flex items-center justify-center shadow-lg">
              <Camera className="h-3.5 w-3.5 text-primary-foreground" />
            </button>
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-foreground truncate" style={{ fontFamily: "'Outfit', sans-serif" }}>
                {authUser.display_name || "Créateur"}
              </h1>
              <button className="shrink-0 h-7 w-7 rounded-full bg-card/60 border border-border/30 flex items-center justify-center">
                <Edit3 className="h-3.5 w-3.5 text-muted-foreground" />
              </button>
            </div>
            <p className="text-xs text-muted-foreground mt-0.5 truncate">{authUser.email}</p>
            <p className="text-[11px] text-muted-foreground/60 mt-1">Artiste multidisciplinaire · Paris 🇫🇷</p>
          </div>
        </div>

        {/* Action buttons */}
        <div className="flex gap-2 mt-4">
          <button className="flex-1 h-9 rounded-xl bg-primary/10 text-primary text-xs font-semibold active:scale-95 transition-all touch-manipulation">
            Modifier
          </button>
          <button className="h-9 w-9 rounded-xl bg-card/60 border border-border/30 flex items-center justify-center active:scale-95 transition-all touch-manipulation">
            <Share2 className="h-4 w-4 text-muted-foreground" />
          </button>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-4 gap-2">
        {[
          { num: "12", label: "Œuvres", icon: Palette, color: "text-primary" },
          { num: "156", label: "Followers", icon: Users, color: "text-cyan-400" },
          { num: "89", label: "Suivis", icon: User, color: "text-green-400" },
          { num: "1.2k", label: "Likes", icon: Heart, color: "text-red-400" },
        ].map((stat) => (
          <div key={stat.label} className="flex flex-col items-center justify-center py-3 rounded-2xl bg-card/60 border border-border/30">
            <stat.icon className={`h-4 w-4 ${stat.color} mb-1`} />
            <span className="text-lg font-bold text-foreground" style={{ fontFamily: "'Outfit', sans-serif" }}>{stat.num}</span>
            <span className="text-[9px] text-muted-foreground uppercase tracking-[0.05em]">{stat.label}</span>
          </div>
        ))}
      </div>

      {/* Tab Navigation */}
      <div className="flex gap-1 bg-card/60 border border-border/30 rounded-xl p-1">
        {[
          { id: "gallery" as const, label: "Galerie", icon: Grid3X3 },
          { id: "activity" as const, label: "Activité", icon: Clock },
          { id: "stats" as const, label: "Stats", icon: TrendingUp },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-medium transition-all duration-200 ${
              activeTab === tab.id
                ? "bg-primary/15 text-primary"
                : "text-muted-foreground"
            }`}
          >
            <tab.icon className="h-3.5 w-3.5" />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Gallery Tab */}
      {activeTab === "gallery" && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80" style={{ fontFamily: "'Outfit', sans-serif" }}>
              Mes Créations
            </h3>
            <div className="flex gap-1">
              <button
                onClick={() => setShowGallery("grid")}
                className={`h-8 w-8 rounded-lg flex items-center justify-center ${showGallery === "grid" ? "bg-primary/15 text-primary" : "text-muted-foreground"}`}
              >
                <Grid3X3 className="h-4 w-4" />
              </button>
              <button
                onClick={() => setShowGallery("list")}
                className={`h-8 w-8 rounded-lg flex items-center justify-center ${showGallery === "list" ? "bg-primary/15 text-primary" : "text-muted-foreground"}`}
              >
                <List className="h-4 w-4" />
              </button>
            </div>
          </div>

          {showGallery === "grid" ? (
            <div className="grid grid-cols-2 gap-3">
              {GALLERY_ITEMS.map((item) => (
                <div key={item.id} className="rounded-2xl bg-card border border-border/30 overflow-hidden active:scale-[0.97] transition-transform duration-100 touch-manipulation">
                  <div className={`h-32 bg-gradient-to-br ${item.gradient} flex items-center justify-center relative`}>
                    <span className="text-4xl">{item.emoji}</span>
                    <div className="absolute top-2 right-2 flex items-center gap-1 bg-black/30 backdrop-blur-sm rounded-full px-2 py-0.5">
                      <Eye className="h-3 w-3 text-white/80" />
                      <span className="text-[10px] text-white/80">{item.views}</span>
                    </div>
                  </div>
                  <div className="p-3">
                    <h4 className="text-sm font-semibold text-foreground truncate">{item.title}</h4>
                    <p className="text-[10px] text-muted-foreground mt-0.5">{item.category}</p>
                    <div className="flex items-center gap-1 mt-2">
                      <Heart className="h-3 w-3 text-red-400" />
                      <span className="text-[10px] text-muted-foreground">{item.likes}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="space-y-2">
              {GALLERY_ITEMS.map((item) => (
                <div key={item.id} className="flex items-center gap-3 p-3 rounded-2xl bg-card border border-border/30 active:scale-[0.98] transition-transform duration-100 touch-manipulation">
                  <div className={`h-12 w-12 rounded-xl bg-gradient-to-br ${item.gradient} flex items-center justify-center shrink-0`}>
                    <span className="text-xl">{item.emoji}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className="text-sm font-semibold text-foreground truncate">{item.title}</h4>
                    <p className="text-[10px] text-muted-foreground">{item.category}</p>
                  </div>
                  <div className="text-right shrink-0">
                    <div className="flex items-center gap-1">
                      <Heart className="h-3 w-3 text-red-400" />
                      <span className="text-[10px] text-muted-foreground">{item.likes}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Eye className="h-3 w-3 text-muted-foreground/50" />
                      <span className="text-[10px] text-muted-foreground/50">{item.views}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Activity Tab */}
      {activeTab === "activity" && (
        <div className="space-y-3">
          <h3 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80" style={{ fontFamily: "'Outfit', sans-serif" }}>
            Activité Récente
          </h3>
          {ACTIVITY_ITEMS.map((item) => (
            <div key={item.id} className="flex items-center gap-3 p-3 rounded-2xl bg-card border border-border/30">
              <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                <span className="text-lg">{item.emoji}</span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm text-foreground">
                  <span className="font-semibold">{item.user}</span>{" "}
                  <span className="text-muted-foreground">{item.content}</span>
                </p>
                <p className="text-[10px] text-muted-foreground/50 mt-0.5">{item.time}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Stats Tab */}
      {activeTab === "stats" && (
        <div className="space-y-4">
          <h3 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80" style={{ fontFamily: "'Outfit', sans-serif" }}>
            Statistiques
          </h3>
          
          {/* Performance card */}
          <div className="rounded-2xl bg-gradient-to-br from-primary/10 to-accent/5 border border-border/30 p-4">
            <div className="flex items-center gap-2 mb-3">
              <Trophy className="h-5 w-5 text-amber-400" />
              <span className="text-sm font-semibold text-foreground" style={{ fontFamily: "'Outfit', sans-serif" }}>Performance</span>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="text-center p-3 rounded-xl bg-card/60">
                <p className="text-2xl font-bold text-primary" style={{ fontFamily: "'Outfit', sans-serif" }}>1.2k</p>
                <p className="text-[10px] text-muted-foreground uppercase">Vues totales</p>
              </div>
              <div className="text-center p-3 rounded-xl bg-card/60">
                <p className="text-2xl font-bold text-cyan-400" style={{ fontFamily: "'Outfit', sans-serif" }}>89%</p>
                <p className="text-[10px] text-muted-foreground uppercase">Engagement</p>
              </div>
            </div>
          </div>

          {/* Top creations */}
          <div className="rounded-2xl bg-card/60 border border-border/30 p-4">
            <div className="flex items-center gap-2 mb-3">
              <Flame className="h-5 w-5 text-red-400" />
              <span className="text-sm font-semibold text-foreground" style={{ fontFamily: "'Outfit', sans-serif" }}>Top Créations</span>
            </div>
            <div className="space-y-2">
              {GALLERY_ITEMS.slice(0, 3).map((item, i) => (
                <div key={item.id} className="flex items-center gap-3">
                  <span className="text-lg font-bold text-muted-foreground/30" style={{ fontFamily: "'Outfit', sans-serif" }}>#{i + 1}</span>
                  <div className={`h-8 w-8 rounded-lg bg-gradient-to-br ${item.gradient} flex items-center justify-center`}>
                    <span className="text-sm">{item.emoji}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-foreground truncate">{item.title}</p>
                    <p className="text-[10px] text-muted-foreground">{item.likes} likes · {item.views} vues</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Menu Items */}
      <div className="rounded-2xl bg-card/60 border border-border/30 overflow-hidden divide-y divide-border/20">
        {[
          { icon: Heart, label: "Favoris", color: "text-red-400", badge: 24 },
          { icon: Bookmark, label: "Enregistrés", color: "text-amber-400", badge: 8 },
          { icon: Bell, label: "Notifications", color: "text-cyan-400", badge: 3 },
          { icon: Settings, label: "Paramètres", color: "text-muted-foreground", action: () => setShowSettings(true) },
        ].map((item) => (
          <button
            key={item.label}
            onClick={item.action}
            className="flex items-center gap-3 w-full p-3.5 active:bg-card/60 transition-colors duration-100 touch-manipulation"
          >
            <item.icon className={`h-5 w-5 shrink-0 ${item.color}`} />
            <span className="flex-1 text-left text-sm font-medium text-foreground">{item.label}</span>
            {item.badge && (
              <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary/15 text-[10px] font-bold text-primary px-1.5">
                {item.badge}
              </span>
            )}
            <ChevronRight className="h-4 w-4 text-muted-foreground/30" />
          </button>
        ))}
      </div>

      {/* Logout */}
      <button
        onClick={handleLogout}
        className="flex items-center gap-3 w-full p-3.5 rounded-2xl bg-red-500/5 border border-red-500/10 active:bg-red-500/10 transition-colors duration-100 touch-manipulation"
      >
        <LogOut className="h-5 w-5 text-red-400" />
        <span className="text-sm font-medium text-red-400">Déconnexion</span>
      </button>

      {/* Version info */}
      <div className="p-3 rounded-xl bg-card/40 border border-border/30 text-center">
        <p className="text-[10px] text-muted-foreground/50 uppercase tracking-[0.2em]">Artéïa v1.0.0</p>
      </div>
    </div>
  );
}