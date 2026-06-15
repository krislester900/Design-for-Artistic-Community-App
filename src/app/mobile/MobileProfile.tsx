/** MobileProfile — Profil utilisateur et paramètres */
import { useState, useEffect } from "react";
import { User, Settings, LogOut, Shield, Heart, Palette, Bookmark, Bell } from "lucide-react";
import { signIn, signUp, signInWithGoogle, signOut as doSignOut, getCurrentSession, onAuthChange, type AuthUser } from "../services/auth";
import { hasSupabaseEnv } from "../lib/supabase";

const MENU_ITEMS = [
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
    const { error } = await signIn(email, password);
    if (error) setMessage(error);
    setIsSubmitting(false);
  }

  async function handleSignUp(e: React.FormEvent) {
    e.preventDefault();
    setIsSubmitting(true);
    const { error } = await signUp(email, password);
    if (error) setMessage(error);
    else setMessage("Compte créé ! Vérifie tes emails.");
    setIsSubmitting(false);
  }

  async function handleGoogleSignIn() {
    const { error } = await signInWithGoogle();
    if (error) setMessage(error);
  }

  async function handleLogout() {
    await doSignOut();
    setAuthUser(null);
  }

  if (showAuth && !authUser) {
    return (
      <div className="px-4 py-6 pb-20">
        <button onClick={() => setShowAuth(false)} className="text-primary text-sm mb-4 touch-manipulation">
          ← Retour
        </button>
        <h2 className="text-xl font-bold text-foreground mb-6">Connexion</h2>

        {message && (
          <div className="rounded-xl bg-primary/10 border border-primary/30 p-3 mb-4 text-xs text-primary">{message}</div>
        )}

        {hasSupabaseEnv && (
          <button onClick={handleGoogleSignIn} className="flex items-center justify-center gap-2 w-full rounded-xl border border-border bg-card/60 p-3 text-sm font-medium text-foreground active:scale-95 transition-all touch-manipulation mb-3">
            <svg className="h-5 w-5" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            Google
          </button>
        )}

        <form onSubmit={handleSignIn} className="space-y-3">
          <input className="w-full h-10 rounded-xl border border-border bg-card/60 px-3 text-sm outline-none focus:border-primary/50" type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} required />
          <input className="w-full h-10 rounded-xl border border-border bg-card/60 px-3 text-sm outline-none focus:border-primary/50" type="password" placeholder="Mot de passe" value={password} onChange={e => setPassword(e.target.value)} required minLength={6} />
          <button disabled={isSubmitting || !hasSupabaseEnv} className="w-full h-11 rounded-xl bg-gradient-to-r from-primary to-accent text-primary-foreground font-semibold text-sm active:scale-95 transition-all touch-manipulation disabled:opacity-50" type="submit">
            {isSubmitting ? "..." : "Se connecter"}
          </button>
          <button onClick={handleSignUp} type="button" className="w-full h-10 rounded-xl text-sm text-primary active:scale-95 touch-manipulation">
            Créer un compte
          </button>
        </form>
      </div>
    );
  }

  return (
    <div className="px-4 py-6 space-y-5 pb-20">
      {/* Profile header */}
      <div className="flex items-center gap-4 p-4 rounded-3xl bg-gradient-to-br from-primary/10 via-background to-accent/5 border border-border/30">
        <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary to-accent shadow-xl shadow-primary/20">
          <User className="h-7 w-7 text-primary-foreground" />
        </div>
        <div>
          <h1 className="text-lg font-bold text-foreground">
            {authUser ? (authUser.display_name || "Créateur") : "Invité"}
          </h1>
          <p className="text-xs text-muted-foreground">
            {authUser ? authUser.email : "Connecte-toi pour commencer"}
          </p>
        </div>
      </div>

      {!authUser ? (
        <button onClick={() => setShowAuth(true)} className="w-full h-12 rounded-2xl bg-gradient-to-r from-primary to-accent text-primary-foreground font-semibold text-sm active:scale-95 transition-all touch-manipulation shadow-lg shadow-primary/20">
          Se connecter
        </button>
      ) : (
        <>
          {/* Menu */}
          <div className="space-y-1">
            {MENU_ITEMS.map((item) => (
              <button key={item.label} className="flex items-center gap-3 w-full p-3 rounded-xl active:bg-card/60 transition-all touch-manipulation">
                <div className={`${item.color}`}>
                  <item.icon className="h-5 w-5" />
                </div>
                <span className="text-sm text-foreground">{item.label}</span>
              </button>
            ))}
          </div>

          {/* Logout */}
          <button onClick={handleLogout} className="flex items-center gap-3 w-full p-3 rounded-xl active:bg-red-500/10 transition-all touch-manipulation">
            <LogOut className="h-5 w-5 text-red-400" />
            <span className="text-sm text-red-400">Déconnexion</span>
          </button>

          <div className="p-3 rounded-xl bg-card/40 border border-border/30">
            <p className="text-xs text-muted-foreground">Artéïa v1.0.0</p>
          </div>
        </>
      )}
    </div>
  );
}