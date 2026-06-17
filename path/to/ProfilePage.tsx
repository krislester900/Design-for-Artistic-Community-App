import { useState, useEffect } from "react";
import { ProfileBird } from "./WelcomeBird"; // Importez le composant ProfileBird

export function ProfilePage() {
  // ... (votre code existant)

  return (
    <div className="px-6 py-10">
      {/* ... (autres éléments) */}

      {/* Ajoutez le ProfileBird en haut à gauche */}
      <ProfileBird />

      {/* ... (autres éléments) */}
    </div>
  );
}
