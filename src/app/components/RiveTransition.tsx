import { useEffect, useState, useRef } from "react";

type RiveTransitionProps = {
  /** Callback appelé une fois la transition terminée */
  onComplete?: () => void;
  /** Durée de la transition en ms */
  duration?: number;
};

/**
 * RiveTransition
 * 
 * Affiche une animation de transition "cloudy walk" entre les pages.
 * Utilise l'URL publique du fichier .riv placé dans /public/animations/
 * Charge Rive via le canvas et rive-wasm
 */
export function RiveTransition({ onComplete, duration = 1500 }: RiveTransitionProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    let mounted = true;
    let riveCleanup: (() => void) | null = null;

    const loadRive = async () => {
      try {
        const { Rive } = await import("@rive-app/react-canvas");

        const canvas = canvasRef.current;
        if (!canvas || !mounted) return;

        if (typeof Rive === "function") {
          const instance = new Rive({
            src: "/animations/cloudy-walk.riv",
            canvas,
            autoplay: true,
          });
          riveCleanup = () => instance.cleanup?.();
        }
      } catch (err) {
        console.warn("Rive animation could not be loaded:", err);
      }
    };

    loadRive();

    // Auto-dismiss after duration
    const timer = setTimeout(() => {
      if (mounted) {
        setVisible(false);
        onComplete?.();
        riveCleanup?.();
      }
    }, duration);

    return () => {
      mounted = false;
      clearTimeout(timer);
      riveCleanup?.();
    };
  }, [onComplete, duration]);

  if (!visible) return null;

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 99999,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "#0a0a0a",
        pointerEvents: "all",
      }}
    >
      <canvas
        ref={canvasRef}
        style={{
          width: "100%",
          height: "100%",
          maxWidth: "600px",
          maxHeight: "600px",
        }}
      />
    </div>
  );
}