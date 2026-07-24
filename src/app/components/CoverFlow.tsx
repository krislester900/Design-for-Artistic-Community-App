import React, { useState, useRef, useEffect } from "react";
import type { Song } from "../types/song";
import { itunesService } from "../services/itunes";

function ReflectionComponent({
  song,
  index,
  currentIndex,
  getCover,
}: {
  song: Song;
  index: number;
  currentIndex: number;
  getCover?: (song: Song) => string | null;
}) {
  const albumCover = getCover ? getCover(song) : null;

  if (!albumCover) {
    return null;
  }

  return (
    <div
      className="absolute top-full left-0 w-full h-full rounded-lg pointer-events-none select-none transition-all duration-500"
      style={{
        backgroundImage: `url(${albumCover})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
        transform: "scaleY(-1) translateY(0px)",
        opacity: index === currentIndex ? 0.9 : 0.75,
        maskImage:
          "linear-gradient(to top, rgba(255,255,255,0.75) 0%, rgba(255,255,255,0.4) 20%, rgba(255,255,255,0.15) 40%, transparent 60%)",
        WebkitMaskImage:
          "linear-gradient(to top, rgba(255,255,255,0.75) 0%, rgba(255,255,255,0.4) 20%, rgba(255,255,255,0.15) 40%, transparent 60%)",
        filter: "blur(0.5px) brightness(0.6) contrast(1.3)",
      }}
    />
  );
}

interface CoverFlowProps {
  songs: Song[];
  onSongSelect: (song: Song) => void;
  selectedSong: Song | null;
  isPlaying?: boolean;
  getCover?: (song: Song) => string | null;
}

export function CoverFlow({
  songs,
  onSongSelect,
  selectedSong,
  isPlaying = false,
  getCover,
}: CoverFlowProps) {
  const [currentIndex, setCurrentIndex] = useState(() => Math.floor(songs.length / 2));
  const [isDragging, setIsDragging] = useState(false);
  const [dragOffset, setDragOffset] = useState(0);
  const trackRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (selectedSong) {
      const idx = songs.findIndex((s) => s.id === selectedSong.id);
      if (idx >= 0) setCurrentIndex(idx);
    }
  }, [selectedSong, songs]);

  const handlePointerDown = (e: React.PointerEvent) => {
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
    setIsDragging(true);
    setDragOffset(0);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!isDragging) return;
    setDragOffset(e.movementX);
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    if (!isDragging) return;
    (e.target as HTMLElement).releasePointerCapture(e.pointerId);
    setIsDragging(false);
    if (dragOffset > 60 && currentIndex > 0) {
      setCurrentIndex((i) => i - 1);
    } else if (dragOffset < -60 && currentIndex < songs.length - 1) {
      setCurrentIndex((i) => i + 1);
    }
    setDragOffset(0);
  };

  const coverFor = (song: Song) => {
    const base = (song as Song & { coverUrl?: string }).coverUrl || (song as any).albumCover;
    return base || null;
  };

  return (
    <div className="relative w-full select-none">
      <div
        className="relative flex items-center justify-center"
        style={{ height: 420 }}
        ref={trackRef}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
      >
        {songs.map((song, idx) => {
          const offset = idx - currentIndex;
          const isSelected = idx === currentIndex;
          const translateX = offset * 140 + (isDragging ? dragOffset : 0);
          const scale = isSelected ? 1 : 0.85;
          const zIndex = isSelected ? 30 : 10;
          const rotateY = Math.max(-25, Math.min(25, offset * -18));
          const opacity = Math.abs(offset) > 3 ? 0 : 1;

          return (
            <div
              key={song.id}
              className="absolute top-1/2 -translate-y-1/2 transition-all duration-500 ease-out"
              style={{
                width: 240,
                height: 300,
                transform: `translateX(${translateX}px) scale(${scale}) perspective(700px) rotateY(${rotateY}deg)`,
                zIndex,
                opacity,
                transformOrigin: "center center",
              }}
              onClick={() => {
                if (!isDragging) onSongSelect(song);
              }}
            >
              <div
                className={`relative w-full h-full rounded-2xl overflow-hidden border-2 shadow-2xl transition-all duration-300 ${
                  isSelected
                    ? "border-white/80 shadow-[0_20px_60px_rgba(0,0,0,0.6)]"
                    : "border-white/20 shadow-[0_10px_30px_rgba(0,0,0,0.4)]"
                }`}
              >
                <img
                  src={coverFor(song)}
                  alt={song.title}
                  className="w-full h-full object-cover"
                  draggable={false}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
                <div className="absolute bottom-0 left-0 right-0 p-4">
                  <p className="text-sm font-semibold text-white truncate drop-shadow">{song.title}</p>
                  <p className="text-xs text-white/80 truncate drop-shadow">{song.artist}</p>
                </div>
              </div>
              <ReflectionComponent
                song={song}
                index={idx}
                currentIndex={currentIndex}
                getCover={coverFor}
              />
            </div>
          );
        })}
      </div>

      <div className="mt-6 flex items-center justify-center gap-4">
        <button
          onClick={() => setCurrentIndex((i) => Math.max(0, i - 1))}
          disabled={currentIndex === 0}
          className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white transition-colors hover:bg-white/20 disabled:opacity-30"
        >
          ←
        </button>
        <span className="text-sm text-white/80">
          {currentIndex + 1} / {songs.length}
        </span>
        <button
          onClick={() => setCurrentIndex((i) => Math.min(songs.length - 1, i + 1))}
          disabled={currentIndex === songs.length - 1}
          className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white transition-colors hover:bg-white/20 disabled:opacity-30"
        >
          →
        </button>
      </div>
    </div>
  );
}