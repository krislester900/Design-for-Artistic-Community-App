/**
 * MobileProfile — Écran Profil (Spec v2)
 * Avatar gradient, stats, menu items, logout
 */
import { useState, useEffect } from "react";
import { User, Settings, LogOut, Heart, Palette, Bookmark, Bell, ChevronRight } from "lucide-react";
import { signIn, signUp, signInWithGoogle, signOut as doSignOut, getCurrentSession, onAuthChange, type AuthUser } from "../services/auth";
import { hasSupabaseEnv } from "../lib/supabase";

interface MenuItem {
  icon: typeof Heart;
  label: string;
  color: string;
}

const MENU_ITEMS: MenuItem[] = [
  { icon: Heart, label: "Favoris", color: "text-red-400" },
  { icon: Bookmark, label: "Enregistrés", color: "text-amber-400" },
  { icon: Palette, label: "Mes créations", color: "text-primary" },
  { icon: Bell, label: "Notifications", color: "text-cyan-400" },
  { icon: Settings, label: "Paramètres", color: "text-muted-foreground" },
];

export function MobileProfile() {
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [showAuth, setShowAuth] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState("");

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

  // Auth form view
  if (showAuth && !authUser) {
    return (
      <div className="px-4 py-6 pb-24">
        <button onClick={() => setShowAuth(false)} className="text-primary text-sm font-medium mb-6 touch-manipulation">
          ← Retour au profil
        </button>
        <h2 className="text-xl font-bold text-foreground mb-6">Connexion</h2>

        {message && (
          <div className="rounded-xl bg-primary/10 border border-primary/20 p-3 mb-4 text-xs text-primary leading-relaxed">
            {message}
          </div>
        )}

        {/* Google Sign-In */}
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

        {/* Divider */}
        {hasSupabaseEnv && (
          <div className="flex items-center gap-3 mb-3">
            <div className="flex-1 border-t border-border/40" />
            <span className="text-[10px] uppercase tracking-[0.2em] text-muted-foreground/40">ou</span>
            <div className="flex-1 border-t border-border/40" />
          </div>
        )}

        {/* Email/Password form */}
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
        {/* Avatar + Info */}
        <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-primary/10 via-background to-accent/5 border border-border/30 p-6 text-center">
          <div className="relative mx-auto mb-4 h-20 w-20 flex items-center justify-center rounded-full bg-gradient-to-br from-primary to-accent shadow-xl shadow-primary/20">
            <User className="h-9 w-9 text-primary-foreground" />
          </div>
          <h1 className="text-xl font-bold text-foreground">Invité</h1>
          <p className="text-xs text-muted-foreground mt-1">Connecte-toi pour commencer à créer</p>
          <button
            onClick={() => setShowAuth(true)}
            className="mt-5 w-full h-11 rounded-xl bg-gradient-to-r from-primary to-accent text-primary-foreground font-semibold text-sm active:scale-95 transition-all touch-manipulation shadow-lg shadow-primary/20"
          >
            Se connecter
          </button>
        </div>

        {/* Version info */}
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
        {/* Background glow */}
        <div className="absolute -top-10 -right-10 h-24 w-24 rounded-full bg-primary/15 blur-2xl" />
        <div className="absolute -bottom-8 -left-8 h-20 w-20 rounded-full bg-accent/10 blur-2xl" />

        {/* Avatar with gradient border */}
        <div className="relative mx-auto mb-4">
          <div className="h-20 w-20 rounded-full bg-gradient-to-br from-primary via-primary to-accent p-[3px] shadow-xl shadow-primary/20">
            <div className="flex h-full w-full items-center justify-center rounded-full bg-background">
              <span className="text-2xl font-bold text-primary">
                {authUser.display_name?.charAt(0) || authUser.email?.charAt(0)?.toUpperCase() || "C"}
              </span>
            </div>
          </div>
        </div>

        <h1 className="text-center text-xl font-bold text-foreground">
          {authUser.display_name || "Créateur"}
        </h1>
        <p className="text-center text-xs text-muted-foreground mt-1 truncate px-4">
          {authUser.email}
        </p>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-3 gap-3">
        {[
          { num: "12", label: "Œuvres" },
          { num: "156", label: "Followers" },
          { num: "89", label: "Suivis" },
        ].map((stat) => (
          <div key={stat.label} className="flex flex-col items-center justify-center py-3 rounded-2xl bg-card/60 border border-border/30">
            <span className="text-xl font-bold text-foreground">{stat.num}</span>
            <span className="text-[10px] text-muted-foreground uppercase tracking-[0.1em] mt-1">{stat.label}</span>
          </div>
        ))}
      </div>

      {/* Menu Items */}
      <div className="rounded-2xl bg-card/60 border border-border/30 overflow-hidden divide-y divide-border/20">
        {MENU_ITEMS.map((item) => (
          <button
            key={item.label}
            className="flex items-center gap-3 w-full p-3.5 active:bg-card/60 transition-colors duration-100 touch-manipulation"
          >
            <item.icon className={`h-5 w-5 shrink-0 ${item.color}`} />
            <span className="flex-1 text-left text-sm font-medium text-foreground">{item.label}</span>
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