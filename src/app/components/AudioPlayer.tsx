import { useState, useRef, useEffect, useCallback } from "react";
import { Play, Pause, SkipForward, SkipBack, Volume2, VolumeX, Heart } from "lucide-react";
import type { MusicTrack } from "../data/music";

type AudioPlayerProps = {
  track: MusicTrack | null;
  onNext?: () => void;
  onPrev?: () => void;
  autoPlay?: boolean;
};

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, "0")}`;
}

export function AudioPlayer({ track, onNext, onPrev, autoPlay = false }: AudioPlayerProps) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [playing, setPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(0.7);
  const [muted, setMuted] = useState(false);
  const [liked, setLiked] = useState(false);

  useEffect(() => {
    if (!track) return;
    const audio = new Audio(track.audioUrl);
    audio.volume = volume;
    audioRef.current = audio;

    const onTime = () => setCurrentTime(audio.currentTime);
    const onMeta = () => setDuration(audio.duration);
    const onEnd = () => {
      setPlaying(false);
      setCurrentTime(0);
      onNext?.();
    };

    audio.addEventListener("timeupdate", onTime);
    audio.addEventListener("loadedmetadata", onMeta);
    audio.addEventListener("ended", onEnd);

    if (autoPlay) {
      audio.play().catch(() => {});
      setPlaying(true);
    }

    return () => {
      audio.removeEventListener("timeupdate", onTime);
      audio.removeEventListener("loadedmetadata", onMeta);
      audio.removeEventListener("ended", onEnd);
      audio.pause();
      audio.src = "";
    };
  }, [track?.id]);

  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = muted ? 0 : volume;
    }
  }, [volume, muted]);

  const togglePlay = useCallback(() => {
    const audio = audioRef.current;
    if (!audio) return;
    if (playing) {
      audio.pause();
    } else {
      audio.play().catch(() => {});
    }
    setPlaying(!playing);
  }, [playing]);

  const seek = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const audio = audioRef.current;
    if (!audio) return;
    const time = Number(e.target.value);
    audio.currentTime = time;
    setCurrentTime(time);
  }, []);

  if (!track) {
    return (
      <div className="flex items-center gap-4 rounded-2xl border border-border/50 bg-card/80 p-4 backdrop-blur">
        <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-muted text-muted-foreground">
          <Play className="h-5 w-5" />
        </div>
        <p className="text-sm text-muted-foreground">Aucun morceau sélectionné</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-3 rounded-2xl border border-border/50 bg-card/90 p-4 backdrop-blur shadow-lg">
      <div className="flex items-center gap-4">
        <img
          src={track.coverUrl}
          alt={track.title}
          className="h-14 w-14 shrink-0 rounded-xl object-cover shadow"
        />
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold text-foreground">{track.title}</p>
          <p className="truncate text-xs text-muted-foreground">{track.artist}</p>
        </div>
        <button
          onClick={() => setLiked(!liked)}
          className={`flex h-8 w-8 items-center justify-center rounded-full transition-colors ${
            liked ? "text-red-500" : "text-muted-foreground hover:text-red-400"
          }`}
        >
          <Heart className={`h-4 w-4 ${liked ? "fill-red-500" : ""}`} />
        </button>
      </div>

      <div className="flex items-center gap-2">
        <span className="w-10 text-right text-[10px] text-muted-foreground font-mono">
          {formatTime(currentTime)}
        </span>
        <input
          type="range"
          min={0}
          max={duration || 100}
          value={currentTime}
          onChange={seek}
          className="flex-1 h-1 appearance-none rounded-full bg-muted [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-primary cursor-pointer"
        />
        <span className="w-10 text-left text-[10px] text-muted-foreground font-mono">
          {formatTime(duration)}
        </span>
      </div>

      <div className="flex items-center justify-center gap-4">
        {onPrev && (
          <button onClick={onPrev} className="text-muted-foreground hover:text-foreground transition-colors">
            <SkipBack className="h-5 w-5" />
          </button>
        )}
        <button
          onClick={togglePlay}
          className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-lg shadow-primary/20 transition-all hover:scale-105 active:scale-95"
        >
          {playing ? <Pause className="h-5 w-5" /> : <Play className="h-5 w-5" />}
        </button>
        {onNext && (
          <button onClick={onNext} className="text-muted-foreground hover:text-foreground transition-colors">
            <SkipForward className="h-5 w-5" />
          </button>
        )}
        <button
          onClick={() => setMuted(!muted)}
          className="ml-auto text-muted-foreground hover:text-foreground transition-colors"
        >
          {muted ? <VolumeX className="h-4 w-4" /> : <Volume2 className="h-4 w-4" />}
        </button>
        <input
          type="range"
          min={0}
          max={1}
          step={0.01}
          value={muted ? 0 : volume}
          onChange={(e) => { setVolume(Number(e.target.value)); setMuted(false); }}
          className="w-16 h-1 appearance-none rounded-full bg-muted [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:h-2.5 [&::-webkit-slider-thumb]:w-2.5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-primary cursor-pointer"
        />
      </div>
    </div>
  );
}
