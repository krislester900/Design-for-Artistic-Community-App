/**
 * AuthService — Service d'authentification public pour Artéïa.
 * Gère inscription, connexion, déconnexion et OAuth Google.
 */

import { hasSupabaseEnv, supabase } from "../lib/supabase";

export interface AuthUser {
  id: string;
  email: string;
  avatar_url?: string;
  display_name?: string;
}

/**
 * Vérifie si l'utilisateur est connecté et retourne sa session
 */
export async function getCurrentSession() {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: "Supabase n'est pas configuré." };
  }
  const { data, error } = await supabase.auth.getSession();
  if (error) throw error;
  const sessionUser = data.session?.user;
  const user: AuthUser | null = sessionUser
    ? {
        id: sessionUser.id,
        email: sessionUser.email ?? "",
        avatar_url: sessionUser.user_metadata?.avatar_url,
        display_name: sessionUser.user_metadata?.full_name ?? sessionUser.user_metadata?.name,
      }
    : null;
  return { user, error: null };
}

/**
 * Inscription d'un nouvel utilisateur
 */
export async function signUp(email: string, password: string) {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: "Supabase n'est pas configuré. Configure le fichier .env." };
  }
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: window.location.origin + "/connexion.html",
    },
  });
  if (error) return { user: null, error: error.message };
  return { user: data.user, error: null };
}

/**
 * Connexion email/mot de passe
 */
export async function signIn(email: string, password: string) {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: "Supabase n'est pas configuré. Configure le fichier .env." };
  }
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { user: null, error: error.message };
  return { user: data.user, error: null };
}

/**
 * Connexion avec Google OAuth
 */
export async function signInWithGoogle() {
  if (!hasSupabaseEnv || !supabase) {
    return { error: "Supabase n'est pas configuré. Configure le fichier .env." };
  }
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: window.location.origin + "/index.html",
      queryParams: {
        access_type: "offline",
        prompt: "consent",
      },
    },
  });
  if (error) return { error: error.message };
  return { data, error: null };
}

/**
 * Connexion avec Google (popup pour Capacitor mobile)
 */
export async function signInWithGoogleMobile() {
  if (!hasSupabaseEnv || !supabase) {
    return { error: "Supabase n'est pas configuré." };
  }
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      skipBrowserRedirect: true,
      redirectTo: "arteia://auth/callback",
    },
  });
  if (error) return { error: error.message };
  // Open the OAuth URL in system browser
  if (data?.url) {
    window.open(data.url, "_blank");
  }
  return { data, error: null };
}

/**
 * Déconnexion
 */
export async function signOut() {
  if (!hasSupabaseEnv || !supabase) return;
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

/**
 * S'abonne aux changements d'état d'authentification
 */
export function onAuthChange(callback: (user: AuthUser | null) => void) {
  if (!hasSupabaseEnv || !supabase) {
    return { unsubscribe: () => {} };
  }
  const { data } = supabase.auth.onAuthStateChange((_event, session) => {
    if (session?.user) {
      callback({
        id: session.user.id,
        email: session.user.email ?? "",
        avatar_url: session.user.user_metadata?.avatar_url,
        display_name: session.user.user_metadata?.full_name ?? session.user.user_metadata?.name,
      });
    } else {
      callback(null);
    }
  });
  return data.subscription;
}

/**
 * Récupère l'URL de l'avatar (fallback initials)
 */
export function getAvatarUrl(user: AuthUser | null): string {
  if (user?.avatar_url) return user.avatar_url;
  return "";
}
