import { useEffect, useState } from "react";
import { WelcomeBird } from "./WelcomeBird";

export function MobileHome() {
  const [isDataLoading, setIsDataLoading] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => setIsDataLoading(false), 1500);
    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="mobile-home relative w-full h-full">
      <WelcomeBird />
      <div className="mobile-home-content p-4">
        {isDataLoading ? (
          <div className="loading-spinner">Chargement...</div>
        ) : (
          <div className="home-grid">
            <h2 className="text-lg font-semibold">Accueil</h2>
            <p className="text-sm text-muted-foreground">Bienvenue sur Artéïa</p>
          </div>
        )}
      </div>
    </div>
  );
}