import { useEffect, useState } from "react";
import { getCurrentSession, type AuthUser } from "../services/auth";
import { ProfileBird } from "./ProfileBird";

interface ProfilePageProps {
  user?: AuthUser;
}

export default function ProfilePage({ user: initialUser }: ProfilePageProps) {
  const [user, setUser] = useState<AuthUser | null>(initialUser || null);
  const [loading, setLoading] = useState(!initialUser);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (initialUser) return;

    const fetchUser = async () => {
      const { user, error } = await getCurrentSession();
      if (error) {
        setError(error.message);
      } else {
        setUser(user);
      }
      setLoading(false);
    };

    fetchUser();
  }, [initialUser]);

  if (loading) return <div className="loading">Chargement du profil...</div>;
  if (error) return <div className="error">Erreur : {error}</div>;
  if (!user) return <div className="error">Aucun utilisateur trouvé.</div>;

  return (
    <div className="profile-page relative">
      <ProfileBird />

      <div className="profile-header">
        <div className="avatar">
          {user.avatar_url ? (
            <img src={user.avatar_url} alt="Avatar" />
          ) : (
            <div className="avatar-placeholder">
              {user.display_name.charAt(0).toUpperCase()}
            </div>
          )}
        </div>
        <h2>{user.display_name}</h2>
        <p>{user.email}</p>
      </div>

      <div className="profile-actions">
        <button className="edit-btn">Modifier le profil</button>
      </div>

      <div className="upload-section">
        <h3>Mes Créations</h3>
        <div className="upload-box">
          <p>Glissez-déposez vos œuvres ici</p>
          <input type="file" multiple />
        </div>
      </div>
    </div>
  );
}
