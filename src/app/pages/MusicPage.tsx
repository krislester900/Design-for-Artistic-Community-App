import { useState, useEffect, useCallback, useMemo } from "react";
import {
  Headphones,
  TrendingUp,
  Sparkles,
  Radio,
  Upload,
  Music,
  Play,
  Pause,
  Heart,
  Clock,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import type { MusicTrack, MusicGenre } from "../data/music";
import { MUSIC_GENRES } from "../data/music";
import { getTrendingTracks, getMusicTracksByGenre } from "../services/music";
import { AudioPlayer } from "../components/AudioPlayer";
import { CoverFlow } from "../components/CoverFlow";
import { itunesService } from "../services/itunes";

type Props = {
  onNavigate?: (page: string) => void;
};

export function MusicPage({ onNavigate }: Props) {
  const [featured, setFeatured] = useState<MusicTrack[]>([]);
  const [selectedGenre, setSelectedGenre] = useState<string | null>(null);
  const [genreTracks, setGenreTracks] = useState<MusicTrack[]>([]);
  const [currentTrack, setCurrentTrack] = useState<MusicTrack | null>(null);
  const [loading, setLoading] = useState(true);
  const [genreCarouselIndex, setGenreCarouselIndex] = useState(0);

  useEffect(() => {
    getTrendingTracks(6).then((t) => { setFeatured(t); setLoading(false); });
  }, []);

  useEffect(() => {
    if (selectedGenre) {
      getMusicTracksByGenre(selectedGenre).then(setGenreTracks);
    }
  }, [selectedGenre]);

  const visibleGenres = useMemo(() => {
    const start = genreCarouselIndex;
    const end = start + 4;
    return MUSIC_GENRES.slice(start, end);
  }, [genreCarouselIndex]);

  const nextGenres = useCallback(() => {
    if (genreCarouselIndex + 4 < MUSIC_GENRES.length) {
      setGenreCarouselIndex((i) => i + 1);
    }
  }, [genreCarouselIndex]);

  const prevGenres = useCallback(() => {
    if (genreCarouselIndex > 0) {
      setGenreCarouselIndex((i) => i - 1);
    }
  }, [genreCarouselIndex]);

  const currentIndex = currentTrack
    ? featured.findIndex((t) => t.id === currentTrack.id)
    : -1;

  const playTrack = useCallback((track: MusicTrack) => {
    setCurrentTrack(track);
  }, []);

  const nextTrack = useCallback(() => {
    if (currentIndex < featured.length - 1) {
      setCurrentTrack(featured[currentIndex + 1]);
    }
  }, [currentIndex, featured]);

  const prevTrack = useCallback(() => {
    if (currentIndex > 0) {
      setCurrentTrack(featured[currentIndex - 1]);
    }
  }, [currentIndex, featured]);

  const [uploadMode, setUploadMode] = useState(false);
  const [uploadTitle, setUploadTitle] = useState("");
  const [uploadGenre, setUploadGenre] = useState("electronic");
  const [uploading, setUploading] = useState(false);

  const handleUpload = useCallback(async () => {
    if (!uploadTitle.trim()) return;
    setUploading(true);
    await new Promise((r) => setTimeout(r, 1500));
    setUploading(false);
    setUploadMode(false);
    setUploadTitle("");
  }, [uploadTitle]);

  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <div className="mb-8 flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-violet-500 to-pink-500 shadow-lg">
              <Headphones className="h-5 w-5 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-foreground">Musique</h1>
              <p className="text-sm text-muted-foreground">
                Explore, écoute et partage ta créativité musicale
              </p>
            </div>
          </div>
        </div>
        <button
          onClick={() => setUploadMode(!uploadMode)}
          className="flex items-center gap-2 rounded-full bg-gradient-to-r from-violet-600 to-pink-600 px-5 py-2.5 text-sm font-medium text-white shadow-lg transition-all hover:scale-105 hover:shadow-xl active:scale-95"
        >
          <Upload className="h-4 w-4" />
          {uploadMode ? "Annuler" : "Publier"}
        </button>
      </div>

      {uploadMode && (
        <div className="mb-8 rounded-2xl border border-border/50 bg-card/80 p-6 backdrop-blur">
          <h2 className="mb-4 text-lg font-semibold text-foreground">Publier un morceau</h2>
          <div className="flex flex-col gap-4">
            <input
              type="text"
              placeholder="Titre du morceau"
              value={uploadTitle}
              onChange={(e) => setUploadTitle(e.target.value)}
              className="rounded-xl border border-border/50 bg-background/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-violet-500 focus:ring-1 focus:ring-violet-500/30"
            />
            <select
              value={uploadGenre}
              onChange={(e) => setUploadGenre(e.target.value)}
              className="rounded-xl border border-border/50 bg-background/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-violet-500 focus:ring-1 focus:ring-violet-500/30"
            >
              {MUSIC_GENRES.map((g) => (
                <option key={g.slug} value={g.slug}>{g.name}</option>
              ))}
            </select>
            <div className="flex items-center justify-center rounded-xl border-2 border-dashed border-border/50 p-8 text-center">
              <div className="flex flex-col items-center gap-2 text-muted-foreground">
                <Music className="h-8 w-8" />
                <p className="text-sm">Glisse ton fichier audio ici</p>
                <p className="text-xs">MP3, WAV, FLAC — Max 50 Mo</p>
                <button
                  onClick={() => {}}
                  className="mt-2 rounded-full bg-primary px-5 py-2 text-xs font-medium text-primary-foreground transition-all hover:bg-primary/90"
                >
                  Choisir un fichier
                </button>
              </div>
            </div>
            <button
              onClick={handleUpload}
              disabled={uploading || !uploadTitle.trim()}
              className="w-full rounded-full bg-gradient-to-r from-violet-600 to-pink-600 py-2.5 text-sm font-medium text-white transition-all hover:scale-[1.02] hover:shadow-xl disabled:opacity-50 disabled:hover:scale-100"
            >
              {uploading ? "Publication en cours..." : "Publier le morceau"}
            </button>
          </div>
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <div className="flex flex-col items-center gap-4">
            <div className="h-10 w-10 animate-spin rounded-full border-[3px] border-violet-500/20 border-t-violet-500" />
            <p className="text-sm text-muted-foreground">Chargement des morceaux...</p>
          </div>
        </div>
      ) : (
        <>
          <div className="mb-8">
            <div className="mb-4 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <TrendingUp className="h-4 w-4 text-violet-500" />
                <h2 className="text-lg font-semibold text-foreground">Tendances</h2>
              </div>
              <div className="flex gap-1">
                <button
                  onClick={prevTrack}
                  disabled={currentIndex <= 0}
                  className="flex h-8 w-8 items-center justify-center rounded-lg bg-card/50 text-muted-foreground transition-colors hover:bg-card disabled:opacity-30"
                >
                  <ChevronLeft className="h-4 w-4" />
                </button>
                <button
                  onClick={nextTrack}
                  disabled={currentIndex >= featured.length - 1}
                  className="flex h-8 w-8 items-center justify-center rounded-lg bg-card/50 text-muted-foreground transition-colors hover:bg-card disabled:opacity-30"
                >
                  <ChevronRight className="h-4 w-4" />
                </button>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-6">
              {featured.slice(0, 6).map((track) => (
                <button
                  key={track.id}
                  onClick={() => playTrack(track)}
                  className={`group relative overflow-hidden rounded-2xl border transition-all hover:scale-[1.02] hover:shadow-xl active:scale-[0.98] ${
                    currentTrack?.id === track.id
                      ? "border-violet-500/50 shadow-violet-500/20"
                      : "border-border/30"
                  }`}
                >
                  <div className="aspect-square overflow-hidden">
                    <img
                      src={track.coverUrl}
                      alt={track.title}
                      className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
                    />
                    <div className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 transition-opacity group-hover:opacity-100">
                      {currentTrack?.id === track.id ? (
                        <Pause className="h-8 w-8 text-white drop-shadow" />
                      ) : (
                        <Play className="h-8 w-8 text-white drop-shadow" />
                      )}
                    </div>
                    <div
                      className="absolute right-2 top-2 rounded-full px-2 py-0.5 text-[10px] font-medium text-white backdrop-blur-sm"
                      style={{ backgroundColor: MUSIC_GENRES.find((g) => g.slug === track.genre)?.color + "99" || "#888" }}
                    >
                      {track.genre}
                    </div>
                  </div>
                  <div className="bg-card p-2.5 text-left">
                    <p className="truncate text-sm font-medium text-foreground">{track.title}</p>
                    <p className="truncate text-xs text-muted-foreground">{track.artist}</p>
                    <div className="mt-1 flex items-center justify-between">
                      <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
                        <Heart className="h-3 w-3" />
                        <span>{track.likes >= 1000 ? `${(track.likes / 1000).toFixed(1)}k` : track.likes}</span>
                      </div>
                      <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
                        <Play className="h-3 w-3" />
                        <span>{track.plays >= 1000 ? `${(track.plays / 1000).toFixed(1)}k` : track.plays}</span>
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>

          <div className="mb-10">
            <div className="mb-2 flex items-center gap-2">
              <Music className="h-4 w-4 text-violet-500" />
              <h2 className="text-lg font-semibold text-foreground">Cover Flow</h2>
            </div>
            <CoverFlow
              songs={featured.map((t) => ({ id: t.id, title: t.title, artist: t.artist, albumCover: t.coverUrl, youtubeId: "" }))}
              selectedSong={currentTrack ? { id: currentTrack.id, title: currentTrack.title, artist: currentTrack.artist, albumCover: currentTrack.coverUrl, youtubeId: "" } : null}
              onSongSelect={(song) => {
                const found = featured.find((t) => t.id === song.id);
                if (found) playTrack(found);
              }}
              getCover={(song) => song.albumCover || null}
            />
          </div>

          <div className="mb-8">
            <div className="mb-4 flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-amber-500" />
              <h2 className="text-lg font-semibold text-foreground">Genres</h2>
            </div>
            <div className="flex items-center gap-2">
              {prevGenres && MUSIC_GENRES.length > 4 && (
                <button
                  onClick={prevGenres}
                  disabled={genreCarouselIndex === 0}
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-card/50 text-muted-foreground transition-colors hover:bg-card disabled:opacity-30"
                >
                  <ChevronLeft className="h-5 w-5" />
                </button>
              )}
              <div className="flex flex-1 gap-3 overflow-hidden">
                {visibleGenres.map((genre) => (
                  <button
                    key={genre.slug}
                    onClick={() => setSelectedGenre(genre.slug === selectedGenre ? null : genre.slug)}
                    className={`flex flex-1 flex-col items-center gap-2 rounded-2xl border p-4 transition-all hover:scale-[1.03] hover:shadow-lg ${
                      selectedGenre === genre.slug
                        ? "border-transparent text-white shadow-xl"
                        : "border-border/30 text-foreground"
                    }`}
                    style={{
                      backgroundColor: selectedGenre === genre.slug ? genre.color : undefined,
                    }}
                  >
                    <div
                      className="flex h-12 w-12 items-center justify-center rounded-xl"
                      style={{ backgroundColor: genre.color + "20" }}
                    >
                      <Radio className="h-5 w-5" style={{ color: genre.color }} />
                    </div>
                    <span className="text-sm font-medium">{genre.name}</span>
                    <span className="text-xs text-muted-foreground">{genre.count} morceaux</span>
                  </button>
                ))}
              </div>
              {MUSIC_GENRES.length > 4 && (
                <button
                  onClick={nextGenres}
                  disabled={genreCarouselIndex + 4 >= MUSIC_GENRES.length}
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-card/50 text-muted-foreground transition-colors hover:bg-card disabled:opacity-30"
                >
                  <ChevronRight className="h-5 w-5" />
                </button>
              )}
            </div>

            {selectedGenre && (
              <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
                {genreTracks.map((track) => (
                  <button
                    key={track.id}
                    onClick={() => playTrack(track)}
                    className={`flex items-center gap-3 rounded-xl border p-3 text-left transition-all hover:border-violet-500/30 hover:shadow-md ${
                      currentTrack?.id === track.id ? "border-violet-500/50 bg-violet-500/5" : "border-border/30"
                    }`}
                  >
                    <img
                      src={track.coverUrl}
                      alt={track.title}
                      className="h-10 w-10 shrink-0 rounded-lg object-cover"
                    />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-foreground">{track.title}</p>
                      <p className="truncate text-xs text-muted-foreground">{track.artist}</p>
                    </div>
                    {currentTrack?.id === track.id ? (
                      <Pause className="h-4 w-4 shrink-0 text-violet-500" />
                    ) : (
                      <Play className="h-4 w-4 shrink-0 text-muted-foreground" />
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>

          <div className="mb-8">
            <div className="mb-4 flex items-center gap-2">
              <Clock className="h-4 w-4 text-pink-500" />
              <h2 className="text-lg font-semibold text-foreground">Nouveautés</h2>
            </div>
            <div className="flex flex-col gap-2">
              {featured.slice(0, 4).map((track, idx) => (
                <button
                  key={track.id}
                  onClick={() => playTrack(track)}
                  className={`flex items-center gap-4 rounded-xl border p-3 text-left transition-all hover:border-pink-500/30 hover:shadow-md ${
                    currentTrack?.id === track.id ? "border-pink-500/50 bg-pink-500/5" : "border-border/30"
                  }`}
                >
                  <span className="w-6 text-center text-sm font-bold text-muted-foreground">{idx + 1}</span>
                  <img
                    src={track.coverUrl}
                    alt={track.title}
                    className="h-12 w-12 shrink-0 rounded-lg object-cover"
                  />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-foreground">{track.title}</p>
                    <p className="truncate text-xs text-muted-foreground">{track.artist}</p>
                  </div>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Heart className="h-3 w-3" />
                      {track.likes >= 1000 ? `${(track.likes / 1000).toFixed(1)}k` : track.likes}
                    </span>
                    <span className="flex items-center gap-1">
                      <Play className="h-3 w-3" />
                      {track.plays >= 1000 ? `${(track.plays / 1000).toFixed(1)}k` : track.plays}
                    </span>
                  </div>
                  {currentTrack?.id === track.id ? (
                    <Pause className="h-5 w-5 shrink-0 text-pink-500" />
                  ) : (
                    <Play className="h-5 w-5 shrink-0 text-muted-foreground" />
                  )}
                </button>
              ))}
            </div>
          </div>
        </>
      )}

      <AudioPlayer
        track={currentTrack}
        onNext={currentIndex < featured.length - 1 ? nextTrack : undefined}
        onPrev={currentIndex > 0 ? prevTrack : undefined}
        autoPlay
      />
    </div>
  );
}
