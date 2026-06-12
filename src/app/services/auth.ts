/**
 * AuthService — Service d'authentification public pour Artéïa.
 * Gère l'inscription, la connexion et la déconnexion des utilisateurs.
 */

import { hasSupabaseEnv, supabase } from "../lib/supabase";

export interface AuthUser {
  id: string;
  email: string;
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
  return { user: data.session?.user ?? null, error: null };
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
  if (error) {
    return { user: null, error: error.message };
  }
  return { user: data.user, error: null };
}

/**
 * Connexion d'un utilisateur existant
 */
export async function signIn(email: string, password: string) {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: "Supabase n'est pas configuré. Configure le fichier .env." };
  }
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  if (error) {
    return { user: null, error: error.message };
  }
  return { user: data.user, error: null };
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
      callback({ id: session.user.id, email: session.user.email ?? "" });
    } else {
      callback(null);
    }
  });
  return data.subscription;
}