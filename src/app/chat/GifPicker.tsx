import { useState, useMemo } from "react";
import { X, Search } from "lucide-react";

// Pre-built GIF categories with emoji-based representations
// In production, these would come from GIPHY/Tenor API
const GIF_CATEGORIES = [
  {
    name: "Populaires",
    gifs: [
      { id: "gif-1", name: "Thumbs Up", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExaHR0cm43ZnFqZnFqZnFqZnFqZnFqZnFqZnFqZnFqZnFqZnFqZn/giphy.gif", thumbnail: "👍" },
      { id: "gif-2", name: "Clap", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/l3q2KJjinjChoBMOs/giphy.gif", thumbnail: "👏" },
      { id: "gif-3", name: "Fire", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/YRt7Bqv3nMT3m/giphy.gif", thumbnail: "🔥" },
      { id: "gif-4", name: "Heart Eyes", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/Mq3wXsSxfhN1e/giphy.gif", thumbnail: "😍" },
      { id: "gif-5", name: "LOL", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/3o7btPCcdNniyf00xi/giphy.gif", thumbnail: "😂" },
      { id: "gif-6", name: "Wow", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/l0MYt5jPR6QX5pnqM/giphy.gif", thumbnail: "😮" },
    ],
  },
  {
    name: "Art",
    gifs: [
      { id: "art-gif-1", name: "Painting", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/painting.gif", thumbnail: "🎨" },
      { id: "art-gif-2", name: "Drawing", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/drawing.gif", thumbnail: "✏️" },
      { id: "art-gif-3", name: "Camera", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/camera.gif", thumbnail: "📷" },
      { id: "art-gif-4", name: "Music", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/music.gif", thumbnail: "🎵" },
      { id: "art-gif-5", name: "Film", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/film.gif", thumbnail: "🎬" },
      { id: "art-gif-6", name: "Dance", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/dance.gif", thumbnail: "💃" },
    ],
  },
  {
    name: "Réactions",
    gifs: [
      { id: "react-1", name: "Yes", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/yes.gif", thumbnail: "✅" },
      { id: "react-2", name: "No", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/no.gif", thumbnail: "❌" },
      { id: "react-3", name: "Applause", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/applause.gif", thumbnail: "🎉" },
      { id: "react-4", name: "Mind Blown", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/mindblown.gif", thumbnail: "🤯" },
      { id: "react-5", name: "Crying", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/crying.gif", thumbnail: "😭" },
      { id: "react-6", name: "Angry", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/angry.gif", thumbnail: "😡" },
    ],
  },
  {
    name: "Mème",
    gifs: [
      { id: "meme-1", name: "Smart", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/smart.gif", thumbnail: "🧠" },
      { id: "meme-2", name: "This is fine", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/thisisfine.gif", thumbnail: "🔥" },
      { id: "meme-3", name: "Deal with it", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/deal.gif", thumbnail: "😎" },
      { id: "meme-4", name: "Popcorn", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/popcorn.gif", thumbnail: "🍿" },
      { id: "meme-5", name: "Mic Drop", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/micdrop.gif", thumbnail: "🎤" },
      { id: "meme-6", name: "Tea", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/tea.gif", thumbnail: "☕" },
    ],
  },
];

type GifPickerProps = {
  onSelect: (gifUrl: string) => void;
  onClose: () => void;
};

export function GifPicker({ onSelect, onClose }: GifPickerProps) {
  const [activeCategory, setActiveCategory] = useState(GIF_CATEGORIES[0].name);
  const [search, setSearch] = useState("");

  const categories = useMemo(() => GIF_CATEGORIES.map((c) => c.name), []);

  const activeGifs = useMemo(() => {
    if (search.trim()) {
      return GIF_CATEGORIES.flatMap((c) => c.gifs).filter((g) =>
        g.name.toLowerCase().includes(search.toLowerCase())
      );
    }
    return GIF_CATEGORIES.find((c) => c.name === activeCategory)?.gifs || [];
  }, [activeCategory, search]);

  return (
    <div className="w-full rounded-t-2xl border border-border bg-card shadow-2xl backdrop-blur-xl z-50">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-border px-3 py-2">
        <span className="text-xs font-semibold text-muted-foreground">GIFs</span>
        <button onClick={onClose} className="rounded-md p-1 text-muted-foreground hover:text-foreground transition-colors">
          <X className="h-3.5 w-3.5" />
        </button>
      </div>

      {/* Search */}
      <div className="px-3 py-2">
        <div className="relative">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground/50" />
          <input
            className="w-full rounded-lg border border-border bg-background/50 pl-8 pr-3 py-1.5 text-xs text-foreground outline-none placeholder:text-muted-foreground/40 focus:border-primary"
            placeholder="Rechercher un GIF..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      {/* Category tabs */}
      <div className="flex gap-1 px-3 pb-1 overflow-x-auto">
        {categories.map((cat) => (
          <button
            key={cat}
            onClick={() => { setActiveCategory(cat); setSearch(""); }}
            className={`shrink-0 rounded-lg px-2 py-1 text-[10px] font-medium transition-colors ${
              activeCategory === cat && !search
                ? "bg-primary/15 text-primary"
                : "text-muted-foreground hover:bg-card/60"
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* GIF grid */}
      <div className="grid grid-cols-3 gap-2 px-3 py-2 max-h-56 overflow-y-auto">
        {activeGifs.map((gif) => (
          <button
            key={gif.id}
            onClick={() => { onSelect(gif.thumbnail); onClose(); }}
            className="group relative flex h-20 items-center justify-center rounded-xl bg-muted/50 text-3xl transition-all hover:scale-105 hover:shadow-lg overflow-hidden"
          >
            <span className="group-hover:scale-110 transition-transform">{gif.thumbnail}</span>
            <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors rounded-xl flex items-center justify-center">
              <span className="text-[10px] text-white opacity-0 group-hover:opacity-100 transition-opacity font-medium drop-shadow-lg">
                {gif.name}
              </span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}