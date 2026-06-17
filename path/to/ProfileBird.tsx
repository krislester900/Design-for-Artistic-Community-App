import { useState, useEffect } from "react";
import { animations } from "../animations"; // Importez les animations existantes

// Ajoutez de nouvelles animations pour le ProfileBird (ex: vert et violet)
export const profileAnimations = {
  profileFlyOut: {
    duration: 0.8, // Vitesses ajustées pour mobile
    timing: "ease-out",
    keyframes: [
      { opacity: 1, transform: "translateY(0)" },
      { opacity: 0, transform: "translateY(-15px)" }
    ]
  },
  profileBounce: {
    duration: 0.6,
    timing: "ease-in-out",
    keyframes: [
      { transform: "translateY(0)" },
      { transform: "translateY(-8px)" },
      { transform: "translateY(4px)" },
      { transform: "translateY(0)" }
    ]
  },
  profileCollision: {
    duration: 0.4,
    timing: "linear",
    keyframes: [
      { transform: "translateY(0)" },
      { transform: "translateY(-3px)" },
      { transform: "translateY(3px)" },
      { transform: "translateY(0)" }
    ]
  }
};

export function ProfileBird() {
  const [isFlying, setIsFlying] = useState(true);
  const [isBouncing, setIsBouncing] = useState(false);
  const [isColliding, setIsColliding] = useState(false);

  useEffect(() => {
    // Animation après 2 secondes
    const timer = setTimeout(() => {
      setIsFlying(false);
    }, 2000);
    return () => clearTimeout(timer);
  }, []);

  // Gestion des touches pour interrompre le vol
  useEffect(() => {
    const handleTouch = (e) => {
      if (isFlying) {
        setIsBouncing(true);
        setTimeout(() => {
          setIsBouncing(false);
          setIsColliding(true);
          setTimeout(() => {
            setIsColliding(false);
            setIsFlying(true);
          }, 400);
        }, 300);
      }
    };

    window.addEventListener("touchstart", handleTouch);
    return () => window.removeEventListener("touchstart", handleTouch);
  }, [isFlying]);

  return (
    <div 
      className={`absolute top-0 left-0 right-0 z-50 w-full h-full flex items-center justify-center`} 
      style={{ 
        display: isFlying ? "flex" : isBouncing ? "flex" : isColliding ? "flex" : "none" 
      }}
    >
      <div 
        className={`h-16 w-16 rounded-full bg-gradient-to-br from-green-500 to-purple-500 shadow-lg`} 
        style={{ 
          animation: isFlying ? profileAnimations.profileFlyOut : 
            isBouncing ? profileAnimations.profileBounce : 
            isColliding ? profileAnimations.profileCollision : "none"
        }}
      >
        {/* Détails en vert et violet */}
        <div 
          className={`absolute top-50 left-50 transform -translate-x-50 -translate-y-50`} 
          style={{ 
            width: "8px", 
            height: "12px", 
            background: "green", 
            borderRadius: "50%", 
            animation: isFlying ? profileAnimations.profileFlyOut : 
              isBouncing ? profileAnimations.profileBounce : 
              isColliding ? profileAnimations.profileCollision : "none"
          }}
        />
        <div 
          className={`absolute top-30 left-30 transform -translate-x-30 -translate-y-30`} 
          style={{ 
            width: "6px", 
            height: "8px", 
            background: "purple", 
            borderRadius: "50%", 
            animation: isFlying ? profileAnimations.profileFlyOut : 
              isBouncing ? profileAnimations.profileBounce : 
              isColliding ? profileAnimations.profileCollision : "none"
          }}
        />
      </div>
    </div>
  );
}
