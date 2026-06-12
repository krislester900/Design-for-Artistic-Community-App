import { motion, AnimatePresence } from "motion/react";
import { useEffect, useState } from "react";

const easeOutExpo = [0.16, 1, 0.3, 1] as const;

/* ─── Ink splatter rays ──────────────────────────────────────────── */
const RAYS = [
  { angle:   0, length: 55, width: 18 },
  { angle:  35, length: 70, width: 14 },
  { angle:  72, length: 50, width: 20 },
  { angle: 110, length: 65, width: 12 },
  { angle: 145, length: 58, width: 16 },
  { angle: 180, length: 72, width: 14 },
  { angle: 215, length: 48, width: 18 },
  { angle: 252, length: 68, width: 10 },
  { angle: 290, length: 60, width: 16 },
  { angle: 325, length: 52, width: 20 },
  { angle:  18, length: 80, width:  8 },
  { angle: 160, length: 75, width:  9 },
];

function SplatterRays({ active }: { active: boolean }) {
  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      {RAYS.map((ray, i) => {
        const rad = (ray.angle * Math.PI) / 180;
        const tx = Math.cos(rad) * ray.length;
        const ty = Math.sin(rad) * ray.length;
        return (
          <motion.div
            key={i}
            style={{
              position: "absolute",
              top: "50%",
              left: "50%",
              width: ray.width,
              height: ray.width,
              marginLeft: -ray.width / 2,
              marginTop: -ray.width / 2,
              borderRadius: "50%",
              background: "#0a0a0a",
            }}
            initial={{ x: 0, y: 0, scale: 0, opacity: 0 }}
            animate={
              active
                ? { x: tx, y: ty, scale: 1, opacity: 1 }
                : { x: 0, y: 0, scale: 0, opacity: 0 }
            }
            transition={{
              duration: 0.2,
              delay: i * 0.01,
              ease: [0.2, 0, 0.8, 1],
            }}
          />
        );
      })}
    </div>
  );
}

/* ─── Explosion overlay ──────────────────────────────────────────── */
function ExplosionOverlay({ active }: { active: boolean }) {
  // A black circle that scales up from center to cover the entire screen
  return (
    <motion.div
      style={{
        position: "fixed",
        inset: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        pointerEvents: "none",
        zIndex: 10,
      }}
    >
      <motion.div
        style={{
          width: "100vmax",
          height: "100vmax",
          borderRadius: "50%",
          background: "#0a0a0a",
          position: "absolute",
        }}
        initial={{ scale: 0, opacity: 1 }}
        animate={active ? { scale: 3, opacity: 1 } : { scale: 0, opacity: 1 }}
        transition={{ duration: 0.55, ease: [0.4, 0, 0.2, 1] }}
      />
    </motion.div>
  );
}

/* ─── Smiley ─────────────────────────────────────────────────────── */
function SmileyFace({ step }: { step: number }) {
  const melting = step >= 2;
  const dripping = step >= 3;
  const exploding = step >= 4;

  return (
    <motion.svg
      viewBox="0 0 120 120"
      style={{
        width: "clamp(80px,14vw,140px)",
        height: "clamp(80px,14vw,140px)",
        overflow: "visible",
        position: "relative",
        zIndex: 5,
      }}
      initial={{ opacity: 0, scale: 0.4 }}
      animate={
        exploding
          ? { scale: 1.6, opacity: 0 }
          : step >= 1
          ? { opacity: 1, scale: 1 }
          : { opacity: 0, scale: 0.4 }
      }
      transition={
        exploding
          ? { duration: 0.18, ease: [0.6, 0, 1, 1] }
          : { duration: 0.6, ease: easeOutExpo }
      }
    >
      <motion.ellipse
        cx="60" cy="60" fill="#0a0a0a"
        initial={{ rx: 48, ry: 48, cy: 60 }}
        animate={
          dripping ? { ry: 38, cy: 68, rx: 52 }
          : melting ? { ry: 44, cy: 63, rx: 48 }
          : { ry: 48, cy: 60, rx: 48 }
        }
        transition={{ duration: 0.55, ease: [0.4, 0, 0.2, 1] }}
      />
      <motion.ellipse
        cx="42" fill="white"
        initial={{ cy: 48, rx: 5, ry: 5 }}
        animate={
          dripping ? { cy: 54, ry: 8, rx: 3.5, x: -2 }
          : melting ? { cy: 50, ry: 6, rx: 5 }
          : { cy: 48, ry: 5, rx: 5 }
        }
        transition={{ duration: 0.55, ease: [0.4, 0, 0.2, 1] }}
      />
      <motion.ellipse
        cx="78" fill="white"
        initial={{ cy: 48, rx: 5, ry: 5 }}
        animate={
          dripping ? { cy: 52, ry: 9, rx: 3.5, x: 2 }
          : melting ? { cy: 50, ry: 6, rx: 5 }
          : { cy: 48, ry: 5, rx: 5 }
        }
        transition={{ duration: 0.55, ease: [0.4, 0, 0.2, 1] }}
      />
      <motion.path
        stroke="white" strokeWidth="4" strokeLinecap="round" fill="none"
        initial={{ d: "M 38 72 Q 60 88 82 72" }}
        animate={
          dripping ? { d: "M 38 80 Q 60 68 82 80" }
          : melting ? { d: "M 38 75 Q 60 80 82 75" }
          : { d: "M 38 72 Q 60 88 82 72" }
        }
        transition={{ duration: 0.55, ease: [0.4, 0, 0.2, 1] }}
      />
      <motion.ellipse
        cx="60" cy="115" fill="#0a0a0a"
        initial={{ ry: 0, rx: 8, opacity: 0 }}
        animate={dripping ? { ry: 10, rx: 8, opacity: 1 } : { ry: 0, rx: 8, opacity: 0 }}
        transition={{ duration: 0.3, ease: easeOutExpo }}
      />
    </motion.svg>
  );
}

/* ─── Main ───────────────────────────────────────────────────────── */
export function ArtLoadingScreen({ onComplete }: { onComplete?: () => void }) {
  const [step, setStep] = useState(0);

  useEffect(() => {
    const t = [
      setTimeout(() => setStep(1), 300),   // smiley in
      setTimeout(() => setStep(2), 1100),  // melting
      setTimeout(() => setStep(3), 1850),  // dripping
      setTimeout(() => setStep(4), 2450),  // EXPLODE
      setTimeout(() => setStep(5), 2900),  // ARTÉIA appears
      setTimeout(() => setStep(6), 4600),  // fade out
      setTimeout(() => onComplete?.(), 5000),
    ];
    return () => t.forEach(clearTimeout);
  }, [onComplete]);

  const exploding = step >= 4;
  const logoVisible = step >= 5;

  return (
    <AnimatePresence>
      {step < 6 && (
        <motion.div
          key="loader"
          className="fixed inset-0 z-50 flex flex-col items-center justify-center"
          style={{ backgroundColor: "#f7f5f0" }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.45 }}
          role="alert"
          aria-label="Chargement en cours"
        >
          {/* Pre-explosion: smiley phase */}
          <AnimatePresence>
            {!exploding && (
              <motion.div
                key="smiley-stage"
                className="flex flex-col items-center"
                exit={{ opacity: 0 }}
                transition={{ duration: 0.05 }}
                style={{ position: "relative" }}
              >
                <SmileyFace step={step} />
                <SplatterRays active={false} />
              </motion.div>
            )}
          </AnimatePresence>

          {/* Explosion moment — rays burst out then black circle swallows all */}
          {exploding && (
            <div style={{ position: "fixed", inset: 0, zIndex: 8 }}>
              <SplatterRays active={true} />
              <ExplosionOverlay active={true} />
            </div>
          )}

          {/* Black stage: ARTÉIA on black */}
          <AnimatePresence>
            {logoVisible && (
              <motion.div
                key="logo-stage"
                style={{
                  position: "fixed",
                  inset: 0,
                  zIndex: 20,
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  justifyContent: "center",
                  backgroundColor: "#0a0a0a",
                }}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.3 }}
              >
                <motion.div
                  style={{ textAlign: "center" }}
                  initial={{ opacity: 0, y: 24, filter: "blur(8px)" }}
                  animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
                  transition={{ duration: 0.8, ease: easeOutExpo }}
                >
                  <p
                    style={{
                      fontFamily: "'Alien Block', cursive",
                      fontSize: "clamp(52px, 11vw, 120px)",
                      fontWeight: 900,
                      letterSpacing: "-0.02em",
                      color: "#f7f5f0",
                      lineHeight: 0.9,
                      margin: 0,
                      userSelect: "none",
                    }}
                    aria-label="Artéïa"
                  >
                    ARTÉIA
                  </p>
                  <motion.p
                    style={{
                      fontFamily: "'Alien Block', cursive",
                      fontSize: "clamp(10px, 1.2vw, 13px)",
                      fontStyle: "italic",
                      letterSpacing: "0.35em",
                      color: "#666",
                      margin: "20px 0 0 0",
                    }}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ duration: 0.6, delay: 0.5 }}
                    aria-hidden="true"
                  >
                    revue d'art contemporain
                  </motion.p>
                </motion.div>

                {/* Progress on black */}
                <motion.div
                  style={{
                    position: "absolute",
                    bottom: 40,
                    left: "50%",
                    transform: "translateX(-50%)",
                    width: 64,
                  }}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 0.4 }}
                  transition={{ duration: 0.5, delay: 0.3 }}
                >
                  <div style={{ width: "100%", height: "1px", background: "#333" }}>
                    <motion.div
                      style={{ height: "100%", background: "#f7f5f0", transformOrigin: "left" }}
                      initial={{ scaleX: 0 }}
                      animate={{ scaleX: 1 }}
                      transition={{ duration: 1.6, ease: "linear" }}
                    />
                  </div>
                </motion.div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Progress on white (pre-explosion) */}
          {!exploding && (
            <motion.div
              style={{
                position: "absolute",
                bottom: 40,
                left: "50%",
                transform: "translateX(-50%)",
                width: 64,
              }}
              initial={{ opacity: 0 }}
              animate={{ opacity: step >= 1 ? 0.35 : 0 }}
              transition={{ duration: 0.4 }}
            >
              <div style={{ width: "100%", height: "1px", background: "#ccc" }}>
                <motion.div
                  style={{ height: "100%", background: "#0a0a0a", transformOrigin: "left" }}
                  initial={{ scaleX: 0 }}
                  animate={{ scaleX: 1 }}
                  transition={{ duration: 2.2, ease: "linear" }}
                />
              </div>
            </motion.div>
          )}
        </motion.div>
      )}
    </AnimatePresence>
  );
}