export interface MusicTrack {
  id: string;
  title: string;
  artist: string;
  coverUrl: string;
  audioUrl: string;
  duration: number;
  likes: number;
  plays: number;
  genre: string;
  createdAt: string;
}

export interface MusicGenre {
  slug: string;
  name: string;
  color: string;
  count: number;
}

export const MUSIC_GENRES: MusicGenre[] = [
  { slug: "afro-trap", name: "Afro-Trap", color: "#8b5cf6", count: 24 },
  { slug: "lo-fi", name: "Lo-fi", color: "#10b981", count: 31 },
  { slug: "drill", name: "Drill", color: "#ef4444", count: 18 },
  { slug: "rap-fr", name: "Rap FR", color: "#f59e0b", count: 27 },
  { slug: "electronic", name: "Électronique", color: "#3b82f6", count: 22 },
  { slug: "ambient", name: "Ambient", color: "#06b6d4", count: 15 },
  { slug: "jazz", name: "Jazz", color: "#ec4899", count: 12 },
  { slug: "classical", name: "Classique", color: "#a855f7", count: 9 },
];

export const MUSIC_TRACKS: MusicTrack[] = [
  {
    id: "track-1",
    title: "Pulse Nocturne",
    artist: "Naya Pulse",
    coverUrl: "https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=400&h=400&fit=crop",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    duration: 214,
    likes: 1280,
    plays: 5400,
    genre: "afro-trap",
    createdAt: "2026-06-01",
  },
  {
    id: "track-2",
    title: "Beat Afro-Trap",
    artist: "DJ Artéïa",
    coverUrl: "https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=400&h=400&fit=crop",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    duration: 187,
    likes: 980,
    plays: 4200,
    genre: "afro-trap",
    createdAt: "2026-06-05",
  },
  {
    id: "track-3",
    title: "Lo-fi Vibes",
    artist: "ChillMaster",
    coverUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    duration: 152,
    likes: 756,
    plays: 3200,
    genre: "lo-fi",
    createdAt: "2026-06-10",
  },
  {
    id: "track-4",
    title: "Freestyle Paris",
    artist: "MC Nova",
    coverUrl: "https://images.unsplash.com/photo-1524650359799-842906ca1c06?w=400&h=400&fit=crop",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
    duration: 243,
    likes: 1102,
    plays: 4800,
    genre: "rap-fr",
    createdAt: "2026-06-08",
  },
  {
    id: "track-5",
    title: "Drillwave",
    artist: "BeatKilla",
    coverUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
    duration: 198,
    likes: 890,
    plays: 3600,
    genre: "drill",
    createdAt: "2026-06-12",
  },
  {
    id: "track-6",
    title: "Neon Nights",
    artist: "SynthGirl",
    coverUrl: "https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=400&fit=crop",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3",
    duration: 231,
    likes: 645,
    plays: 2800,
    genre: "electronic",
    createdAt: "2026-06-15",
  },
  {
    id: "track-7",
    title: "Mélancolie",
    artist: "Ari Vox",
    coverUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&h=400&fit=crop",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3",
    duration: 176,
    likes: 534,
    plays: 2100,
    genre: "ambient",
    createdAt: "2026-06-18",
  },
  {
    id: "track-8",
    title: "Jazz Blend",
    artist: "Luma Motion",
    coverUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&h=400&fit=crop",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3",
    duration: 265,
    likes: 423,
    plays: 1900,
    genre: "jazz",
    createdAt: "2026-06-20",
  },
];
