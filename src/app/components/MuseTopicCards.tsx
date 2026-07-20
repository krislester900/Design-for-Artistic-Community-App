import { useState, useCallback, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";

const SUGGESTED_TOPICS = [
  { id: "art", title: "Arts visuels", description: "Peinture, illustration, photo, graphisme" },
  { id: "manga", title: "Manga / BD", description: "Planches, chapitres, narration" },
  { id: "music", title: "Musique", description: "Compositions, beats, textes, arrangements" },
  { id: "film", title: "Films", description: "Scénario, réalisation, montage" },
  { id: "writing", title: "Écriture", description: "Poésie, nouvelles, romans" },
  { id: "animation", title: "Animation", description: "Motion design, 2D/3D" },
];

const swipePower = (offset: number, velocity: number) => Math.abs(offset) * velocity;

export function MuseTopicCards({ onSelect }: { onSelect: (topic: typeof SUGGESTED_TOPICS[number]) => void }) {
  const [index, setIndex] = useState(0);
  const dragOffsetRef = useRef(0);
  const velocityRef = useRef(0);
  const isDraggingRef = useRef(false);

  const paginate = useCallback(() => {
    setIndex((prev) => (prev + 1) % SUGGESTED_TOPICS.length);
  }, []);

  const handleDragEnd = (_: any, { offset, velocity }: any) => {
    const swipe = swipePower(offset.x, velocity.x);
    if (swipe < -5000 || swipe > 5000) {
      paginate();
    }
  };

  const indices = [
    (index - 1 + SUGGESTED_TOPICS.length) % SUGGESTED_TOPICS.length,
    index,
    (index + 1) % SUGGESTED_TOPICS.length,
    (index + 2) % SUGGESTED_TOPICS.length,
  ];

  const scales = [0.8, 1.0, 0.9, 0.85];
  const yOffsets = [12, 0, -12, 0];
  const xOffsets = [62, 0, 32, 48];
  const rotations = [7, 0, 2, 4];

  return (
    <div className="relative mx-auto flex h-[220px] w-full max-w-sm flex-col items-center justify-center">
      <AnimatePresence initial={false}>
        {indices.map((topicIndex, i) => {
          const topic = SUGGESTED_TOPICS[topicIndex];
          return (
            <motion.div
              key={topic.id}
              className="absolute"
              style={{
                left: `${xOffsets[i]}%`,
                top: `${yOffsets[i]}px`,
                rotate: `${rotations[i]}deg`,
              }}
              initial={{ opacity: 0, scale: 0.8, y: 12 }}
              animate={{ opacity: 1, scale: scales[i] }}
              exit={{ opacity: 0, scale: 0.8, y: 12 }}
              transition={{ type: "spring", duration: 0.35, bounce: 0.18 }}
              drag="x"
              dragConstraints={{ left: 0, right: 0, top: 0, bottom: 0 }}
              dragElastic={0.7}
              onDragEnd={handleDragEnd}
              onClick={() => onSelect(topic)}
            >
              <div
                className="w-[280px] h-[220px] rounded-3xl border px-5 py-5 text-left shadow-xl backdrop-blur"
                style={{
                  borderColor: "rgba(255,255,255,0.18)",
                  background: "rgba(255,255,255,0.06)",
                }}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-widest text-white/70">Sujet</p>
                    <h3 className="mt-1 text-xl font-bold text-white">{topic.title}</h3>
                    <p className="mt-1 text-sm text-white/70">{topic.description}</p>
                  </div>
                  <div className="h-10 w-10 rounded-full border border-white/20 bg-white/10 text-center text-xs leading-10 text-white/80">
                    {topicIndex + 1}/{SUGGESTED_TOPICS.length}
                  </div>
                </div>
              </div>
            </motion.div>
          );
        })}
      </AnimatePresence>
    </div>
  );
}

export { SUGGESTED_TOPICS };
