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
    let riveInstance: { cleanup: () => void } | null = null;

    const loadRive = async () => {
      try {
        // Dynamic import of rive-wasm loader from @rive-app/react-canvas
        const riveModule = await import("@rive-app/react-canvas");
        const rive = (riveModule as any).useRive || riveModule.default || riveModule;
        
        const canvas = canvasRef.current;
        if (!canvas || !mounted) return;

        // Try different approaches to load Rive
        const { Rive } = await import("@rive-app/react-canvas");
        
        // @ts-ignore - Rive static method
        if (Rive && typeof Rive.new === "function") {
          // @ts-ignore
          riveInstance = Rive.new({
            src: "/animations/cloudy-walk.riv",
            canvas,
            autoplay: true,
          });
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
        if (riveInstance && typeof riveInstance.cleanup === "function") {
          riveInstance.cleanup();
        }
      }
    }, duration);

    return () => {
      mounted = false;
      clearTimeout(timer);
      if (riveInstance && typeof riveInstance.cleanup === "function") {
        riveInstance.cleanup();
      }
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