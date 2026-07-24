import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";

const CAROUSEL_ITEMS = [
  {
    id: "state-1",
    title: "State 1",
    description: "Purple to pink gradient blend",
    image: "/simple-card-stack/assets/gradient-new.png",
  },
  {
    id: "state-2",
    title: "State 2",
    description: "Smooth gradient transition",
    image: "/simple-card-stack/assets/gradient-smooth.png",
  },
  {
    id: "state-3",
    title: "State 3",
    description: "Organic flowing color blend",
    image: "/simple-card-stack/assets/gradient-flow.png",
  },
  {
    id: "state-4",
    title: "State 4",
    description: "Blue and coral gradient blend",
    image: "/simple-card-stack/assets/gradient-blend.png",
  },
];

const swipePower = (offset: number, velocity: number) => {
  return Math.abs(offset) * velocity;
};

export function CarouselStack() {
  const [indices, setIndices] = useState([0, 1, 2, 3]);

  const paginate = () => {
    setIndices((prev) => [prev[1], prev[2], prev[3], prev[0]]);
  };

  const cardVariants = {
    visible: (i: number) => ({
      opacity: 1,
      zIndex: [4, 3, 2, 1][i] as number,
      scale: [1, 0.9, 0.85, 0.8][i] as number,
      y: [0, -12, 0, 12][i] as number,
      rotate: [0, 2, 4, 7][i] as number,
      x: [0, 32, 48, 62][i] as number,
      transition: {
        type: "spring" as const,
        stiffness: 260,
        damping: 20,
      },
    }),
    exit: { opacity: 0, scale: 0.5, y: 50 },
  } as any;

  return (
    <div className="relative w-full select-none">
      <div className="relative flex items-center justify-center" style={{ height: 520 }}>
        <AnimatePresence initial={false}>
          {indices.map((index, i) => (
            <motion.div
              key={CAROUSEL_ITEMS[index].id}
              custom={i}
              variants={cardVariants}
              initial="exit"
              animate="visible"
              exit="exit"
              drag={true}
              dragConstraints={{ left: 0, right: 0, top: 0, bottom: 0 }}
              dragElastic={0.7}
              onDragEnd={(_e, { offset, velocity }) => {
                const swipe = swipePower(offset.x, velocity.x);
                if (swipe < -10000 || swipe > 10000) {
                  paginate();
                }
              }}
              className="absolute rounded-3xl overflow-hidden border-2 border-white/20 shadow-2xl"
              style={{
                width: 280,
                height: 380,
                touchAction: "none",
                userSelect: "none",
                WebkitUserSelect: "none",
                willChange: "transform",
                WebkitTapHighlightColor: "transparent",
                cursor: "grab",
              }}
            >
              <img
                src={CAROUSEL_ITEMS[index].image}
                alt={CAROUSEL_ITEMS[index].title}
                className="w-full h-full object-cover"
                draggable={false}
                style={{ pointerEvents: "none" }}
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
              <div className="absolute bottom-0 left-0 right-0 p-5">
                <h5 className="text-white text-[15px] font-semibold drop-shadow">{CAROUSEL_ITEMS[index].title}</h5>
                <p className="text-white/80 text-xs drop-shadow">{CAROUSEL_ITEMS[index].description}</p>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      <div className="mt-6 flex items-center justify-center gap-3">
        <button
          onClick={paginate}
          className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white transition-colors hover:bg-white/20"
        >
          ←
        </button>
        <span className="text-sm text-white/80">
          {indices[0] + 1} / {CAROUSEL_ITEMS.length}
        </span>
        <button
          onClick={paginate}
          className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white transition-colors hover:bg-white/20"
        >
          →
        </button>
      </div>
    </div>
  );
}