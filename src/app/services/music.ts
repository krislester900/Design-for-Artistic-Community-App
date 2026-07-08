import { hasSupabaseEnv, supabase } from "../lib/supabase";
import type { MusicTrack } from "../data/music";
import { MUSIC_TRACKS } from "../data/music";

export async function getMusicTracks(): Promise<MusicTrack[]> {
  if (!hasSupabaseEnv || !supabase) {
    return MUSIC_TRACKS;
  }

  try {
    const { data, error } = await supabase
      .from("music_tracks")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    if (data && data.length > 0) {
      return data.map((t: any) => ({
        id: t.id,
        title: t.title,
        artist: t.artist_name || "Artiste",
        coverUrl: t.cover_url || "",
        audioUrl: t.audio_url,
        duration: t.duration || 0,
        likes: t.likes || 0,
        plays: t.plays || 0,
        genre: t.genre || "electronic",
        createdAt: t.created_at,
      }));
    }
    return MUSIC_TRACKS;
  } catch {
    return MUSIC_TRACKS;
  }
}

export async function getMusicTracksByGenre(genre: string): Promise<MusicTrack[]> {
  const tracks = await getMusicTracks();
  return tracks.filter((t) => t.genre === genre);
}

export async function getTrendingTracks(limit = 4): Promise<MusicTrack[]> {
  const tracks = await getMusicTracks();
  return tracks.sort((a, b) => b.plays - a.plays).slice(0, limit);
}
