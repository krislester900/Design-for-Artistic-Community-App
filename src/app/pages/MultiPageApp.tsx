import React, { useState, useEffect } from 'react';
import { 
  signIn, 
  signUp, 
  doSignOut, 
  signInWithGoogle, 
  getCurrentSession, 
  onAuthChange, 
  AuthUser, 
  hasSupabaseEnv 
} from '../services/auth';
import ProfilePage from './ProfilePage';
import ProfileBird from './ProfileBird';

const MultiPageApp = () => {
  const [isProfilePage, setIsProfilePage] = useState(false);
  const [isAuthPage, setIsAuthPage] = useState(true);
  const [isLogin, setIsLogin] = useState(true);
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const checkSession = async () => {
      const { user, error } = await getCurrentSession();
      if (user) setAuthUser(user);
      if (error && error.message !== 'Configuration Supabase manquante') {
        console.error('Session error:', error);
      }
    };

    checkSession();

    const { subscription } = onAuthChange(({ user }) => {
      setAuthUser(user);
    });

    return () => {
      if (subscription) subscription.unsubscribe();
    };
  }, []);

  const showMessage = (msg) => {
    setMessage(msg);
    setTimeout(() => setMessage(''), 5000);
  };

  const handleAuthSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (isLogin) {
        const { user, error } = await signIn(email, password);
        if (error) throw error;
        setAuthUser(user);
        setIsAuthPage(false);
      } else {
        const { user, error } = await signUp(email, password, displayName);
        if (error) throw error;
        setAuthUser(user);
        setIsAuthPage(false);
      }
    } catch (err) {
      showMessage(err.message || 'Une erreur est survenue');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    try {
      const { error } = await signInWithGoogle();
      if (error) throw error;
    } catch (err) {
      showMessage(err.message || 'Erreur Google Sign-In');
    }
  };

  const handleLogout = async () => {
    try {
      const { error } = await doSignOut();
      if (error) throw error;
      setAuthUser(null);
      setIsAuthPage(true);
    } catch (err) {
      showMessage(err.message || 'Erreur de déconnexion');
    }
  };

  const AuthPageSection = () => (
    <div className="auth-container">
      <h2>{isLogin ? 'Connexion' : 'Inscription'}</h2>
      <form onSubmit={handleAuthSubmit}>
        <input 
          type="email" 
          placeholder="Email" 
          value={email} 
          onChange={(e) => setEmail(e.target.value)} 
          required 
        />
        <input 
          type="password" 
          placeholder="Mot de passe" 
          value={password} 
          onChange={(e) => setPassword(e.target.value)} 
          required 
        />
        {!isLogin && (
          <input 
            type="text" 
            placeholder="Nom d'affichage" 
            value={displayName} 
            onChange={(e) => setDisplayName(e.target.value)} 
            required 
          />
        )}
        <button type="submit" disabled={loading || !hasSupabaseEnv}>
          {loading ? 'Chargement...' : (isLogin ? 'Se connecter' : 'S\'inscrire')}
        </button>
      </form>
      <button onClick={() => setIsLogin(!isLogin)}>
        {isLogin ? 'Créer un compte' : 'Déjà un compte ?'}
      </button>
      <button onClick={handleGoogleSignIn} disabled={!hasSupabaseEnv}>
        Continuer avec Google
      </button>
      {message && <p className="message">{message}</p>}
      {!hasSupabaseEnv && <p className="warning">⚠️ Configuration Supabase manquante</p>}
    </div>
  );

  return (
    <div className="app-container">
      <nav className="app-nav">
        <button onClick={() => { setIsAuthPage(false); setIsProfilePage(false); }}>Accueil</button>
        <button onClick={() => { setIsAuthPage(// false); setIsProfilePage(true); }}>Profil</button>
        {authUser && <button onClick={handleLogout}>Déconnexion</button>}
      </nav>

      <main className="app-main">
        {isAuthPage ? (
          <AuthPageSection />
        ) : isProfilePage ? (
          // Protection de la page profil : l'utilisateur doit être connecté
          authUser ? (
            <ProfilePage user={authUser} />
          ) : (
            <div className="error-container">
              <h2>Accès refusé</h2>
              <p>Vous devez être connecté pour accéder à votre profil.</p>
              <button onClick={() => setIsAuthPage(true)}>Se connecter</button>
            </div>
          )
        ) : (
          <div className="home-container">
            <h1>Bienvenue sur Arteia</h1>
            <p>Contenu de la page d'accueil...</p>
            {authUser && <p>Connecté en tant que : {authUser.display_name}</p>}
          </div>
        )}
      </main>
      <div className="app-footer">
        <ProfileBird />
      </div>
    </div>
  );
};

export default MultiPageApp;
