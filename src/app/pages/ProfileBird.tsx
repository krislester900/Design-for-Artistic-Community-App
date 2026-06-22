import { useEffect, useState, type CSSProperties } from "react";

export function ProfileBird() {
  const [isFlying, setIsFlying] = useState(true);
  const [isBouncing, setIsBouncing] = useState(false);
  const [isColliding, setIsColliding] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsFlying(false);
    }, 2000);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    const handleTouch = () => {
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

  const getAnimationStyle = (): CSSProperties => {
    if (isFlying) {
      return {
        animation: "profileFlyOut 0.8s ease-out forwards",
      };
    }
    if (isBouncing) {
      return {
        animation: "profileBounce 0.6s ease-in-out",
      };
    }
    if (isColliding) {
      return {
        animation: "profileCollision 0.4s linear",
      };
    }
    return { display: "none" };
  };

  return (
    <>
      <style>{`
        @keyframes profileFlyOut {
          0% { opacity: 1; transform: translateY(0); }
          100% { opacity: 0; transform: translateY(-15px); }
        }
        @keyframes profileBounce {
          0% { transform: translateY(0); }
          33% { transform: translateY(-8px); }
          66% { transform: translateY(4px); }
          100% { transform: translateY(0); }
        }
        @keyframes profileCollision {
          0% { transform: translateY(0); }
          25% { transform: translateY(-3px); }
          50% { transform: translateY(3px); }
          100% { transform: translateY(0); }
        }
      `}</style>
      <div 
        className="absolute top-0 left-0 right-0 z-50 w-full h-full flex items-center justify-center pointer-events-none" 
        style={{ 
          display: isFlying || isBouncing || isColliding ? "flex" : "none" 
        }}
      >
        <div 
          className="h-16 w-16 rounded-full bg-gradient-to-br from-green-500 to-purple-500 shadow-lg relative" 
          style={getAnimationStyle()}
        >
          <div 
            className="absolute" 
            style={{ 
              top: "25%", left: "25%",
              width: "8px", 
              height: "12px", 
              background: "rgba(255,255,255,0.6)", 
              borderRadius: "50%",
            }}
          />
          <div 
            className="absolute" 
            style={{ 
              bottom: "20%", right: "20%",
              width: "6px", 
              height: "8px", 
              background: "rgba(255,255,255,0.4)", 
              borderRadius: "50%",
            }}
          />
        </div>
      </div>
    </>
  );
}
