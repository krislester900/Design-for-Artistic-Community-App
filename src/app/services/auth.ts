import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const hasSupabaseEnv = !!(SUPABASE_URL && SUPABASE_ANON_KEY);

const supabase = hasSupabaseEnv 
  ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY) 
  : null;

export type AuthUser = {
  id: string;
  email: string;
  display_name: string;
  avatar_url: string;
};

export async function getCurrentSession() {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: new Error('Configuration Supabase manquante') };
  }

  try {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) return { user: null, error };
    if (!session) return { user: null, error: null };

    const user = {
      id: session.user.id,
      email: session.user.email || '',
      display_name: session.user.user_metadata?.display_name || session.user.email || 'Utilisateur',
      avatar_url: session.user.user_metadata?.avatar_url || '',
    };

    return { user, error: null };
  } catch (error) {
    return { user: null, error: error instanceof Error ? error : new Error('Erreur inconnue lors de la récupération de la session') };
  }
}

export async function signIn(email, password) {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: new Error('Configuration Supabase manquante') };
  }

  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { user: null, error };

  const user = {
    id: data.user.id,
    email: data.user.email || '',
    display_name: data.user.user_metadata?.display_name || data.user.email || 'Utilisateur',
    avatar_url: data.user.user_metadata?.avatar_url || '',
  };

  return { user, error: null };
}

export async function signUp(email, password, displayName) {
  if (!hasSupabaseEnv || !supabase) {
    return { user: null, error: new Error('Configuration Supabase manquante') };
  }

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { display_name: displayName },
    },
  });

  if (error) return { user: null, error };

  const user = {
    id: data.user.id,
    email: data.user.email || '',
    display_name: displayName || data.user.// metadata?.display_name || data.user.email || 'Utilisateur',
    avatar_url: data.user.user_metadata?.avatar_url || '',
  };

  return { user, error: null };
}

export async function doSignOut() {
  if (!hasSupabaseEnv || !supabase) {
    return { error: new Error('Configuration Supabase manquante') };
  }

  const { error } = await supabase.auth.signOut();
  return { error };
}

export async function signInWithGoogle() {
  if (!hasSupabaseEnv || !supabase) {
    return { data: null, error: new Error('Configuration Supabase manquante') };
  }

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
  });

  return { data, error };
}

export async function signInWithGoogleMobile() {
  if (!hasSupabaseEnv || !supabase) {
    return { data: null, error: new Error('Configuration Supabase manquante') };
  }

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: window.location.origin,
    },
  });

  return { data, error };
}

export function onAuthChange(callback) {
  if (!hasSupabaseEnv || !supabase) {
    return { subscription: null };
  }

  const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
    if (session) {
      callback({
        user: {
          id: session.user.id,
          email: session.user.email || '',
          display_name: session.user.user_metadata?.display_name || session.user.email || 'Utilisateur',
          avatar_url: session.user.user_metadata?.avatar_url || '',
        },
        event,
      });
    } else {
      callback({ user: null, event });
    }
  });

  return { subscription };
}

export function getAvatarUrl(user) {
  return user?.avatar_url || '';
}
