import { useState, useEffect } from "react";
import { ProfileBird } from "./ProfileBird"; 
import { getCurrentSession, AuthUser } from "../services/auth";

export function ProfilePage() {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadUserProfile() {
      try {
        setLoading(true);
        const { user, error } = await getCurrentSession();
        if (error) {
          setError(error);
        } else if (!user) {
          setError("Vous devez être connecté pour accéder à cette page.");
        } else {
          setUser(user);
        }
      } catch (err) {
        setError("Une erreur inattendue est survenue lors de la récupération du profil.");
      } finally {
        setLoading(false);
      }
    }

    loadUserProfile();
  }, []);

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primaryViolet mx-auto mb-4"></div>
          <p>Chargement de votre profil...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex h-screen items-center justify-center px-6">
        <div className="text-center p-8 bg-red-100 text-red-700 rounded-2xl shadow-sm">
          <p className="font-semibold">{error}</p>
          <a href="/connexion.html" className="mt-4 inline-block text-sm underline">
            Retour à la connexion
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="relative px-6 py-10 min-h-screen">
      {/* L'oiseau de profil qui anime l'entrée de la page */}
      <ProfileBird />

      <div className="max-w-2xl mx-auto bg-cardDark text-white p-8 rounded-3xl shadow-xl border border-border">
        <div className="flex items-center gap-6 mb-8">
          <div className="h-20 w-20 rounded-full bg-gradient-to-br from-green-500 to-purple-500 flex items-center justify-center text-2xl font-bold overflow-hidden">
            {user?.avatar_url ? (
              <img src={user.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
            ) : (
              user?.display_name?.charAt(0).toUpperCase() || "U"
            )}
          </div>
          <div>
            <h1 className="text-2xl font-bold">{user?.display_name || "Utilisateur Artéïa"}</h1>
            <p className="text-muted-foreground">{user?.email}</p>
          </div>
        </div>

        <div className="space-y-6">
          <section>
            <h2 className="text-lg font-semibold mb-2">Mes Informations</h2>
            <div className="p-4 bg-bgDark rounded-xl border border-border">
              <p className="text-sm text-muted-foreground">ID Utilisateur</p>
              <p className="text-xs font-mono truncate">{user?.id}</p>
            </div>
          </section>
          
          <div className="flex justify-end">
            <button className="px-6 py-2 bg-primaryViolet text-white rounded-full hover:opacity-90 transition-opacity">
              Modifier le profil
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
