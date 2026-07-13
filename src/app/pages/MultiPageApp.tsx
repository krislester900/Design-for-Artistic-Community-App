import { FormEvent, useEffect, useRef, useState, lazy, Suspense } from "react";
import {
  signIn,
  signUp,
  doSignOut,
  signInWithGoogle,
  getCurrentSession,
  onAuthChange,
  type AuthUser,
  hasSupabaseEnv,
} from "../services/auth";
import { categories, categoryLabels, type CategorySlug } from "../data/community";
import { getStaticPagePath, type StaticPageId } from "../lib/page-links";
import ProfilePage from "./ProfilePage";
import { ProfileBird } from "./ProfileBird";
import { MusicPage } from "./MusicPage";
import { OntologyPage } from "./OntologyPage";
import { InboxPage } from "./InboxPage";
import GamesHubPage from "./GamesHubPage";

interface MultiPageAppProps {
  page: StaticPageId;
}

  const categoryPageById: Partial<Record<StaticPageId, Exclude<CategorySlug, "all">>> = {
  music: "music",
  "visual-art": "visual-art",
  manga: "manga",
  film: "film",
  literature: "literature",
  animation: "animation",
  games: "games",
};

export default function MultiPageApp({ page }: MultiPageAppProps) {
  const [isProfilePage, setIsProfilePage] = useState(page === "profile");
  const [isAuthPage, setIsAuthPage] = useState(page === "login" || page === "signup");
  const [isLogin, setIsLogin] = useState(page !== "signup");
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const messageTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (messageTimerRef.current) clearTimeout(messageTimerRef.current);
    };
  }, []);

  useEffect(() => {
    const checkSession = async () => {
      const { user, error } = await getCurrentSession();
      if (user) setAuthUser(user);
      if (error && error.message !== "Configuration Supabase manquante") {
        console.error("Session error:", error);
      }
    };

    checkSession();

    const { subscription } = onAuthChange(({ user }) => {
      setAuthUser(user);
    });

    return () => {
      subscription?.unsubscribe();
    };
  }, []);

  const showMessage = (msg: string) => {
    if (messageTimerRef.current) clearTimeout(messageTimerRef.current);
    setMessage(msg);
    messageTimerRef.current = setTimeout(() => setMessage(""), 5000);
  };

  const handleAuthSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLoading(true);

    try {
      if (isLogin) {
        const { user, error } = await signIn(email, password);
        if (error) throw error;
        setAuthUser(user);
      } else {
        const { user, error } = await signUp(email, password, displayName);
        if (error) throw error;
        setAuthUser(user);
      }

      setIsAuthPage(false);
      setIsProfilePage(true);
    } catch (err) {
      showMessage(err instanceof Error ? err.message : "Une erreur est survenue");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    try {
      const { error } = await signInWithGoogle();
      if (error) throw error;
    } catch (err) {
      showMessage(err instanceof Error ? err.message : "Erreur Google Sign-In");
    }
  };

  const handleLogout = async () => {
    try {
      const { error } = await doSignOut();
      if (error) throw error;
      setAuthUser(null);
      setIsAuthPage(true);
      setIsProfilePage(false);
    } catch (err) {
      showMessage(err instanceof Error ? err.message : "Erreur de déconnexion");
    }
  };

  const AuthPageSection = () => (
    <div className="auth-container">
      <h2>{isLogin ? "Connexion" : "Inscription"}</h2>
      <form onSubmit={handleAuthSubmit}>
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          required
        />
        <input
          type="password"
          placeholder="Mot de passe"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          required
        />
        {!isLogin && (
          <input
            type="text"
            placeholder="Nom d'affichage"
            value={displayName}
            onChange={(event) => setDisplayName(event.target.value)}
            required
          />
        )}
        <button type="submit" disabled={loading || !hasSupabaseEnv}>
          {loading ? "Chargement..." : isLogin ? "Se connecter" : "S'inscrire"}
        </button>
      </form>
      <button onClick={() => setIsLogin(!isLogin)}>
        {isLogin ? "Créer un compte" : "Déjà un compte ?"}
      </button>
      <button onClick={handleGoogleSignIn} disabled={!hasSupabaseEnv}>
        Continuer avec Google
      </button>
      {message && <p className="message">{message}</p>}
      {!hasSupabaseEnv && <p className="warning">Configuration Supabase manquante</p>}
    </div>
  );

  const SecondaryPageSection = () => {
    const categorySlug = categoryPageById[page];

    if (page === "database") {
      return (
        <div className="home-container">
          <h1 style={{ fontFamily: "'Alien Block', cursive" }}>Base de données</h1>
          <p>
            État Supabase : {hasSupabaseEnv ? "configuration détectée" : "configuration manquante"}.
          </p>
          <p>
            Les données communautaires sont chargées depuis Supabase quand les variables
            d'environnement sont présentes.
          </p>
        </div>
      );
    }

    if (page === "games") {
      return <GamesHubPage />;
    }

    if (page === "community") {
      return (
        <div className="home-container">
          <h1 style={{ fontFamily: "'Alien Block', cursive" }}>Communauté</h1>
          <p>Forum, discussions créatives, événements et tendances de la communauté Arteïa.</p>
        </div>
      );
    }

    if (page === "music") {
      return <MusicPage />;
    }

    if (page === "ontology") {
      return <OntologyPage />;
    }

    if (page === "inbox") {
      return <InboxPage />;
    }

    if (categorySlug) {
      const category = categories.find((item) => item.slug === categorySlug);
      return (
        <div className="home-container">
          <h1 style={{ fontFamily: "'Alien Block', cursive" }}>
            {categoryLabels[categorySlug]}
          </h1>
          <p>{category?.description ?? "Explore cet univers artistique."}</p>
        </div>
      );
    }

    return (
      <div className="home-container">
        <h1 style={{ fontFamily: "'Alien Block', cursive" }}>Bienvenue sur Arteia</h1>
        <p>Contenu de la page d'accueil...</p>
        {authUser && <p>Connecté en tant que : {authUser.display_name}</p>}
      </div>
    );
  };

  return (
    <div className="app-container">
      <nav className="app-nav">
        <a href={getStaticPagePath("home")}>Accueil</a>
        <button
          onClick={() => {
            setIsAuthPage(false);
            setIsProfilePage(true);
          }}
        >
          Profil
        </button>
        {authUser && <button onClick={handleLogout}>Déconnexion</button>}
      </nav>

      <main className="app-main">
        {isAuthPage ? (
          <AuthPageSection />
        ) : isProfilePage ? (
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
          <SecondaryPageSection />
        )}
      </main>

      <div className="app-footer">
        <ProfileBird />
      </div>
    </div>
  );
}
