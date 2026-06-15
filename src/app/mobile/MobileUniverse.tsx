/**
 * MobileUniverse — Page univers immersive et visuellement wow
 * Chaque univers a son propre design coloré avec animations vivantes
 */
import { useState, useEffect } from "react";
import { ChevronLeft, Heart, Share2, MessageCircle, Play, Pause, Music4, Palette, BookOpen, Film, Pen, Clapperboard, Star, TrendingUp, Users, Sparkles, Headphones, Eye, BookMarked, Camera, Wand2 } from "lucide-react";
import { supabase, hasSupabaseEnv } from "../lib/supabase";

interface UniverseProps {
  slug: string;
  onBack: () => void;
}

interface UniverseContent {
  title: string;
  subtitle: string;
  emoji: string;
  gradient: string;
  bgPattern: string;
  accentColor: string;
  features: { icon: string; label: string; count: number }[];
  trending: { title: string; artist: string; likes: number; emoji: string }[];
  stats: { label: string; value: string }[];
}

const UNIVERSES: Record<string, UniverseContent> = {
  music: {
    title: "Musique",
    subtitle: "Sons, beats & productions",
    emoji: "🎵",
    gradient: "from-violet-600 via-purple-500 to-fuchsia-500",
    bgPattern: "radial-gradient(circle at 20% 80%, rgba(139,92,246,0.3) 0%, transparent 50%), radial-gradient(circle at 80% 20%, rgba(217,70,239,0.25) 0%, transparent 50%)",
    accentColor: "#8b5cf6",
    features: [
      { icon: "🎧", label: "Beats", count: 24 },
      { icon: "🎤", label: "Vocaux", count: 18 },
      { icon: "🎹", label: "Instrus", count: 31 },
      { icon: "💿", label: "Albums", count: 7 },
    ],
    trending: [
      { title: "Beat Afro-Trap", artist: "DJ Artéïa", likes: 342, emoji: "🔥" },
      { title: "Freestyle Paris", artist: "MC Nova", likes: 218, emoji: "🎤" },
      { title: "Lo-fi Vibes", artist: "ChillMaster", likes: 189, emoji: "🌙" },
      { title: "Drillwave", artist: "BeatKilla", likes: 156, emoji: "⚡" },
    ],
    stats: [
      { label: "Artistes", value: "2.4k" },
      { label: "Morceaux", value: "8.7k" },
      { label: "Écoutes", value: "156k" },
    ],
  },
  "visual-art": {
    title: "Art Visuel",
    subtitle: "Peinture, digital & street art",
    emoji: "🎨",
    gradient: "from-orange-500 via-red-500 to-rose-500",
    bgPattern: "radial-gradient(circle at 30% 70%, rgba(249,115,22,0.3) 0%, transparent 50%), radial-gradient(circle at 70% 30%, rgba(239,68,68,0.25) 0%, transparent 50%)",
    accentColor: "#f97316",
    features: [
      { icon: "🖼️", label: "Toiles", count: 45 },
      { icon: "📱", label: "Digital", count: 67 },
      { icon: "🏗️", label: "Street", count: 12 },
      { icon: "📸", label: "Photos", count: 38 },
    ],
    trending: [
      { title: "Portrait Abstrait", artist: "ArtDiva", likes: 456, emoji: "🎭" },
      { title: "Neon Dreams", artist: "PixelMaster", likes: 321, emoji: "✨" },
      { title: "Street Mural", artist: "UrbanArt", likes: 287, emoji: "🏙️" },
      { title: "Aquarelle Flow", artist: "WaterColor", likes: 198, emoji: "🌊" },
    ],
    stats: [
      { label: "Artistes", value: "3.1k" },
      { label: "Œuvres", value: "12.4k" },
      { label: "Likes", value: "234k" },
    ],
  },
  manga: {
    title: "Manga",
    subtitle: "Drawing, fan arts & reviews",
    emoji: "📚",
    gradient: "from-blue-500 via-cyan-500 to-teal-500",
    bgPattern: "radial-gradient(circle at 25% 75%, rgba(59,130,246,0.3) 0%, transparent 50%), radial-gradient(circle at 75% 25%, rgba(6,182,212,0.25) 0%, transparent 50%)",
    accentColor: "#3b82f6",
    features: [
      { icon: "📖", label: "Chapitres", count: 89 },
      { icon: "✏️", label: "Drawings", count: 56 },
      { icon: "💬", label: "Reviews", count: 34 },
      { icon: "🎭", label: "Cosplay", count: 21 },
    ],
    trending: [
      { title: "Naruto Fan Art", artist: "MangaKing", likes: 567, emoji: "🍥" },
      { title: "One Piece Review", artist: "OtakuPro", likes: 432, emoji: "🏴‍☠️" },
      { title: "Original Character", artist: "ArtistX", likes: 321, emoji: "⚔️" },
      { title: "Manga Panel", artist: "InkMaster", likes: 276, emoji: "🖊️" },
    ],
    stats: [
      { label: "Artistes", value: "1.8k" },
      { label: "Dessins", value: "6.2k" },
      { label: "Lectures", value: "89k" },
    ],
  },
  film: {
    title: "Films",
    subtitle: "Court-métrages & ciné",
    emoji: "🎬",
    gradient: "from-emerald-500 via-teal-500 to-cyan-500",
    bgPattern: "radial-gradient(circle at 20% 60%, rgba(16,185,129,0.3) 0%, transparent 50%), radial-gradient(circle at 80% 40%, rgba(20,184,166,0.25) 0%, transparent 50%)",
    accentColor: "#10b981",
    features: [
      { icon: "🎥", label: "Films", count: 15 },
      { icon: "📽️", label: "Trailers", count: 28 },
      { icon: "🎞️", label: "Scénarios", count: 12 },
      { icon: "🎭", label: "Acteurs", count: 34 },
    ],
    trending: [
      { title: "Ombre et Lumière", artist: "CinéArt", likes: 345, emoji: "🌟" },
      { title: "Court-Métrage Paris", artist: "FilmMaker", likes: 287, emoji: "🗼" },
      { title: "Documentaire Urbain", artist: "DocuVision", likes: 234, emoji: "📹" },
      { title: "Animation 2D", artist: "AnimStudio", likes: 198, emoji: "🎞️" },
    ],
    stats: [
      { label: "Créateurs", value: "1.2k" },
      { label: "Films", value: "3.4k" },
      { label: "Vues", value: "67k" },
    ],
  },
  literature: {
    title: "Littérature",
    subtitle: "Poésie, prose & écriture",
    emoji: "✍️",
    gradient: "from-rose-500 via-pink-500 to-fuchsia-500",
    bgPattern: "radial-gradient(circle at 30% 80%, rgba(244,63,94,0.3) 0%, transparent 50%), radial-gradient(circle at 70% 20%, rgba(236,72,153,0.25) 0%, transparent 50%)",
    accentColor: "#f43f5e",
    features: [
      { icon: "📝", label: "Poèmes", count: 67 },
      { icon: "📖", label: "Nouvelles", count: 23 },
      { icon: "📚", label: "Romans", count: 8 },
      { icon: "💬", label: "Critiques", count: 45 },
    ],
    trending: [
      { title: "Les Mots Perdus", artist: "PoèteNuit", likes: 432, emoji: "🌙" },
      { title: "Chronique Paris", artist: "ÉcrivainX", likes: 321, emoji: "🗼" },
      { title: "Haïkus Modernes", artist: "ZenWriter", likes: 276, emoji: "🌸" },
      { title: "Spoken Word", artist: "VoiceArt", likes: 198, emoji: "🎤" },
    ],
    stats: [
      { label: "Écrivains", value: "2.1k" },
      { label: "Textes", value: "8.9k" },
      { label: "Lectures", value: "123k" },
    ],
  },
  animation: {
    title: "Animation",
    subtitle: "Motion design & anim",
    emoji: "🎞️",
    gradient: "from-cyan-500 via-blue-500 to-indigo-500",
    bgPattern: "radial-gradient(circle at 25% 65%, rgba(6,182,212,0.3) 0%, transparent 50%), radial-gradient(circle at 75% 35%, rgba(99,102,241,0.25) 0%, transparent 50%)",
    accentColor: "#06b6d4",
    features: [
      { icon: "🎯", label: "Motion", count: 34 },
      { icon: "🎨", label: "2D Anim", count: 28 },
      { icon: "🧊", label: "3D Anim", count: 15 },
      { icon: "✨", label: "VFX", count: 21 },
    ],
    trending: [
      { title: "Loop Satisfaisante", artist: "MotionPro", likes: 567, emoji: "🔄" },
      { title: "Character Walk", artist: "AnimStudio", likes: 432, emoji: "🚶" },
      { title: "Particle Effect", artist: "VFXMaster", likes: 321, emoji: "✨" },
      { title: "Stop Motion", artist: "ClayArt", likes: 276, emoji: "🎭" },
    ],
    stats: [
      { label: "Créateurs", value: "1.5k" },
      { label: "Animations", value: "4.2k" },
      { label: "Vues", value: "78k" },
    ],
  },
};

export function MobileUniverse({ slug, onBack }: UniverseProps) {
  const universe = UNIVERSES[slug] || UNIVERSES["music"];
  const [likedItems, setLikedItems] = useState<Set<number>>(new Set());
  const [activeFeature, setActiveFeature] = useState(0);

  const toggleLike = (index: number) => {
    setLikedItems(prev => {
      const next = new Set(prev);
      if (next.has(index)) next.delete(index);
      else next.add(index);
      return next;
    });
  };

  return (
    <div className="flex flex-col h-full bg-background overflow-hidden relative">
      {/* Animated background */}
      <div className="absolute inset-0 pointer-events-none" style={{ background: universe.bgPattern }} />
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/4 left-1/4 h-32 w-32 rounded-full bg-gradient-to-br opacity-20 blur-3xl animate-pulse" style={{ background: `linear-gradient(135deg, ${universe.accentColor}40, transparent)` }} />
        <div className="absolute bottom-1/3 right-1/4 h-24 w-24 rounded-full bg-gradient-to-br opacity-15 blur-3xl animate-pulse" style={{ background: `linear-gradient(135deg, ${universe.accentColor}30, transparent)`, animationDelay: "1s" }} />
      </div>

      {/* Header */}
      <header className="flex items-center gap-3 px-4 py-3 bg-background/80 backdrop-blur-xl border-b border-border/20 shrink-0 relative z-10">
        <button onClick={onBack} className="flex h-9 w-9 items-center justify-center rounded-xl bg-card/60 border border-border/30 active:scale-90 transition-all touch-manipulation">
          <ChevronLeft className="h-5 w-5 text-foreground" />
        </button>
        <div className="flex-1 min-w-0">
          <h1 className="text-lg font-bold text-foreground" style={{ fontFamily: "'Alien Block', cursive" }}>
            {universe.title}
          </h1>
          <p className="text-[11px] text-muted-foreground">{universe.subtitle}</p>
        </div>
        <div className="text-3xl">{universe.emoji}</div>
      </header>

      {/* Content */}
      <div className="flex-1 overflow-y-auto relative z-10" style={{ WebkitOverflowScrolling: "touch" }}>
        {/* Hero Stats */}
        <div className={`mx-4 mt-4 rounded-3xl bg-gradient-to-br ${universe.gradient} p-5 relative overflow-hidden`}>
          <div className="absolute inset-0 bg-black/20" />
          <div className="absolute -top-10 -right-10 h-32 w-32 rounded-full bg-white/10 blur-2xl" />
          <div className="absolute -bottom-10 -left-10 h-24 w-24 rounded-full bg-black/10 blur-2xl" />
          <div className="relative z-10">
            <div className="flex items-center gap-2 mb-4">
              <span className="text-4xl">{universe.emoji}</span>
              <div>
                <h2 className="text-xl font-black text-white" style={{ fontFamily: "'Alien Block', cursive" }}>
                  {universe.title}
                </h2>
                <p className="text-xs text-white/70">{universe.subtitle}</p>
              </div>
            </div>
            <div className="grid grid-cols-3 gap-3">
              {universe.stats.map((stat) => (
                <div key={stat.label} className="text-center">
                  <p className="text-lg font-bold text-white">{stat.value}</p>
                  <p className="text-[10px] text-white/60 uppercase tracking-wider">{stat.label}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Features Grid */}
        <div className="px-4 mt-5">
          <h3 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-3">
            Explorer
          </h3>
          <div className="grid grid-cols-4 gap-2">
            {universe.features.map((feature, i) => (
              <button
                key={feature.label}
                onClick={() => setActiveFeature(i)}
                className={`flex flex-col items-center gap-1.5 p-3 rounded-2xl transition-all duration-200 active:scale-95 touch-manipulation ${
                  activeFeature === i
                    ? `bg-gradient-to-br ${universe.gradient} text-white shadow-lg`
                    : "bg-card border border-border/30 text-foreground"
                }`}
              >
                <span className="text-2xl">{feature.icon}</span>
                <span className="text-[10px] font-medium">{feature.label}</span>
                <span className={`text-[10px] ${activeFeature === i ? "text-white/70" : "text-muted-foreground"}`}>
                  {feature.count}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Trending Section */}
        <div className="px-4 mt-6">
          <div className="flex items-center gap-2 mb-3">
            <TrendingUp className="h-4 w-4 text-red-500" />
            <h3 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80">
              Tendances
            </h3>
          </div>
          <div className="space-y-2">
            {universe.trending.map((item, i) => (
              <div
                key={item.title}
                className="flex items-center gap-3 p-3 rounded-2xl bg-card border border-border/30 active:scale-[0.98] transition-all duration-100 touch-manipulation"
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary/10 to-accent/5 text-lg">
                  {item.emoji}
                </div>
                <div className="flex-1 min-w-0">
                  <h4 className="text-sm font-semibold text-foreground truncate">{item.title}</h4>
                  <p className="text-[11px] text-muted-foreground">{item.artist}</p>
                </div>
                <button
                  onClick={() => toggleLike(i)}
                  className={`flex items-center gap-1 px-3 py-1.5 rounded-full transition-all duration-200 active:scale-95 ${
                    likedItems.has(i)
                      ? "bg-red-500/15 text-red-500"
                      : "bg-muted/50 text-muted-foreground"
                  }`}
                >
                  <Heart className={`h-3.5 w-3.5 ${likedItems.has(i) ? "fill-red-500" : ""}`} />
                  <span className="text-[11px] font-medium">{item.likes + (likedItems.has(i) ? 1 : 0)}</span>
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="px-4 mt-6 pb-8">
          <h3 className="text-sm font-semibold uppercase tracking-[0.15em] text-foreground/80 mb-3">
            Actions rapides
          </h3>
          <div className="grid grid-cols-2 gap-3">
            <button className={`flex items-center gap-3 p-4 rounded-2xl bg-gradient-to-br ${universe.gradient} text-white active:scale-[0.97] transition-all duration-100 touch-manipulation shadow-lg`}>
              <Sparkles className="h-5 w-5" />
              <div className="text-left">
                <p className="text-sm font-bold">Publier</p>
                <p className="text-[10px] text-white/70">Créer du contenu</p>
              </div>
            </button>
            <button className="flex items-center gap-3 p-4 rounded-2xl bg-card border border-border/30 text-foreground active:scale-[0.97] transition-all duration-100 touch-manipulation">
              <Users className="h-5 w-5 text-primary" />
              <div className="text-left">
                <p className="text-sm font-bold">Découvrir</p>
                <p className="text-[10px] text-muted-foreground">Voir les artistes</p>
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}