import type { AuthChangeEvent, User } from "@supabase/supabase-js";
import { hasSupabaseEnv, supabase } from "../lib/supabase";

export { hasSupabaseEnv };

export type AuthUser = {
  id: string;
  email: string;
  display_name: string;
  avatar_url: string;
};

type AuthResult = {
  user: AuthUser | null;
  error: Error | null;
};

type AuthChangePayload = {
  user: AuthUser | null;
  event: AuthChangeEvent | "NO_SUPABASE";
};

function missingConfigError() {
  return new Error("Configuration Supabase manquante");
}

function toAuthUser(user: User): AuthUser {
  return {
    id: user.id,
    email: user.email || "",
    display_name: user.user_metadata?.display_name || user.email || "Utilisateur",
    avatar_url: user.user_metadata?.avatar_url || "",
  };
}

export async function getCurrentSession(): Promise<AuthResult> {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: missingConfigError() };
  }

  try {
    const {
      data: { session },
      error,
    } = await supabase.auth.getSession();

    if (error) return { user: null, error };
    if (!session) return { user: null, error: null };

    return { user: toAuthUser(session.user), error: null };
  } catch (error) {
    return {
      user: null,
      error:
        error instanceof Error
          ? error
          : new Error("Erreur inconnue lors de la récupération de la session"),
    };
  }
}

export async function signIn(email: string, password: string): Promise<AuthResult> {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: missingConfigError() };
  }

  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { user: null, error };
  if (!data.user) return { user: null, error: new Error("Utilisateur introuvable") };

  return { user: toAuthUser(data.user), error: null };
}

export async function signUp(
  email: string,
  password: string,
  displayName: string,
): Promise<AuthResult> {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: missingConfigError() };
  }

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { display_name: displayName },
    },
  });

  if (error) return { user: null, error };
  if (!data.user) return { user: null, error: new Error("Utilisateur introuvable") };

  const user = toAuthUser(data.user);
  return { user: { ...user, display_name: displayName || user.display_name }, error: null };
}

export async function doSignOut() {
  if (!hasSupabaseEnv || !supabase) {
    return { error: missingConfigError() };
  }

  const { error } = await supabase.auth.signOut();
  return { error };
}

export async function signInWithGoogle() {
  if (!hasSupabaseEnv || !supabase) {
    return { data: null, error: missingConfigError() };
  }

  return supabase.auth.signInWithOAuth({
    provider: "google",
  });
}

export async function signInWithGoogleMobile() {
  if (!hasSupabaseEnv || !supabase) {
    return { data: null, error: missingConfigError() };
  }

  return supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: window.location.origin,
    },
  });
}

export function onAuthChange(callback: (payload: AuthChangePayload) => void) {
  if (!hasSupabaseEnv || !supabase) {
    return { subscription: null };
  }

  const {
    data: { subscription },
  } = supabase.auth.onAuthStateChange((event, session) => {
    callback({
      user: session ? toAuthUser(session.user) : null,
      event,
    });
  });

  return { subscription };
}

export function getAvatarUrl(user?: AuthUser | null) {
  return user?.avatar_url || "";
}
