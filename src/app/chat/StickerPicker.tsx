import { useState, useMemo } from "react";
import { X, Search } from "lucide-react";

const STICKER_CATEGORIES = [
  {
    name: "Artiste",
    stickers: [
      { id: "art-1", name: "Pinceau", url: "🖌️", category: "art" },
      { id: "art-2", name: "Palette", url: "🎨", category: "art" },
      { id: "art-3", name: "Caméra", url: "📷", category: "art" },
      { id: "art-4", name: "Film", url: "🎬", category: "art" },
      { id: "art-5", name: "Micro", url: "🎤", category: "art" },
      { id: "art-6", name: "Notes", url: "🎵", category: "art" },
      { id: "art-7", name: "Studio", url: "🎧", category: "art" },
      { id: "art-8", name: "Crayon", url: "✏️", category: "art" },
      { id: "art-9", name: "Livres", url: "📚", category: "art" },
      { id: "art-10", name: "Étoile", url: "⭐", category: "art" },
      { id: "art-11", name: "Magique", url: "✨", category: "art" },
      { id: "art-12", name: "Inspiré", url: "💡", category: "art" },
    ],
  },
  {
    name: "Émotions",
    stickers: [
      { id: "emo-1", name: "Amour", url: "😍", category: "emotion" },
      { id: "emo-2", name: "Feu", url: "🔥", category: "emotion" },
      { id: "emo-3", name: "Clap", url: "👏", category: "emotion" },
      { id: "emo-4", name: "Rire", url: "😂", category: "emotion" },
      { id: "emo-5", name: "Cool", url: "😎", category: "emotion" },
      { id: "emo-6", name: "Wow", url: "🤯", category: "emotion" },
      { id: "emo-7", name: "Triste", url: "😢", category: "emotion" },
      { id: "emo-8", name: "Colère", url: "😡", category: "emotion" },
      { id: "emo-9", name: "Peur", url: "😱", category: "emotion" },
      { id: "emo-10", name: "Dormir", url: "😴", category: "emotion" },
      { id: "emo-11", name: "Malade", url: "🤒", category: "emotion" },
      { id: "emo-12", name: "Amoureux", url: "🥰", category: "emotion" },
    ],
  },
  {
    name: "Gestes",
    stickers: [
      { id: "gest-1", name: "Pouce haut", url: "👍", category: "gesture" },
      { id: "gest-2", name: "Pouce bas", url: "👎", category: "gesture" },
      { id: "gest-3", name: "Victoire", url: "✌️", category: "gesture" },
      { id: "gest-4", name: "Rock", url: "🤘", category: "gesture" },
      { id: "gest-5", name: "Corps", url: "💪", category: "gesture" },
      { id: "gest-6", name: "Prayer", url: "🙏", category: "gesture" },
      { id: "gest-7", name: "Salut", url: "👋", category: "gesture" },
      { id: "gest-8", name: "Main", url: "🖐️", category: "gesture" },
      { id: "gest-9", name: "Ok", url: "👌", category: "gesture" },
      { id: "gest-10", name: "Coeur", url: "🫶", category: "gesture" },
      { id: "gest-11", name: "Pointage", url: "👉", category: "gesture" },
      { id: "gest-12", name: "Paix", url: "☮️", category: "gesture" },
    ],
  },
  {
    name: "Objets",
    stickers: [
      { id: "obj-1", name: "Cadeau", url: "🎁", category: "object" },
      { id: "obj-2", name: "Diamant", url: "💎", category: "object" },
      { id: "obj-3", name: "Couronne", url: "👑", category: "object" },
      { id: "obj-4", name: "Épée", url: "⚔️", category: "object" },
      { id: "obj-5", name: "Bouclier", url: "🛡️", category: "object" },
      { id: "obj-6", name: "Trophée", url: "🏆", category: "object" },
      { id: "obj-7", name: "Médaille", url: "🥇", category: "object" },
      { id: "obj-8", name: "Bombe", url: "💣", category: "object" },
      { id: "obj-9", name: "Fusée", url: "🚀", category: "object" },
      { id: "obj-10", name: "Arc-en-ciel", url: "🌈", category: "object" },
      { id: "obj-11", name: "Foudre", url: "⚡", category: "object" },
      { id: "obj-12", name: "Snowflake", url: "❄️", category: "object" },
    ],
  },
  {
    name: "Nature",
    stickers: [
      { id: "nat-1", name: "Soleil", url: "☀️", category: "nature" },
      { id: "nat-2", name: "Lune", url: "🌙", category: "nature" },
      { id: "nat-3", name: "Étoile filante", url: "🌠", category: "nature" },
      { id: "nat-4", name: "Fleur", url: "🌸", category: "nature" },
      { id: "nat-5", name: "Rose", url: "🌹", category: "nature" },
      { id: "nat-6", name: "Tournesol", url: "🌻", category: "nature" },
      { id: "nat-7", name: "Arbre", url: "🌳", category: "nature" },
      { id: "nat-8", name: "Feuille", url: "🍃", category: "nature" },
      { id: "nat-9", name: "Pluie", url: "🌧️", category: "nature" },
      { id: "nat-10", name: "Neige", url: "🌨️", category: "nature" },
      { id: "nat-11", name: "Océan", url: "🌊", category: "nature" },
      { id: "nat-12", name: "Papillon", url: "🦋", category: "nature" },
    ],
  },
];

type StickerPickerProps = {
  onSelect: (stickerId: string, stickerUrl: string) => void;
  onClose: () => void;
};

export function StickerPicker({ onSelect, onClose }: StickerPickerProps) {
  const [activeCategory, setActiveCategory] = useState(STICKER_CATEGORIES[0].name);
  const [search, setSearch] = useState("");

  const categories = useMemo(() => STICKER_CATEGORIES.map((c) => c.name), []);

  const activeStickers = useMemo(() => {
    const cat = STICKER_CATEGORIES.find((c) => c.name === activeCategory);
    if (search.trim()) {
      return STICKER_CATEGORIES.flatMap((c) => c.stickers).filter((s) =>
        s.name.toLowerCase().includes(search.toLowerCase())
      );
    }
    return cat?.stickers || [];
  }, [activeCategory, search]);

  return (
    <div className="w-full rounded-t-2xl border border-border bg-card shadow-2xl backdrop-blur-xl z-50">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-border px-3 py-2">
        <span className="text-xs font-semibold text-muted-foreground">Stickers</span>
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
            placeholder="Rechercher un sticker..."
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

      {/* Sticker grid */}
      <div className="grid grid-cols-6 gap-2 px-3 py-2 max-h-48 overflow-y-auto">
        {activeStickers.map((sticker) => (
          <button
            key={sticker.id}
            onClick={() => { onSelect(sticker.id, sticker.url); onClose(); }}
            className="flex h-14 w-14 items-center justify-center rounded-xl text-3xl hover:bg-primary/10 transition-all hover:scale-110"
            title={sticker.name}
          >
            {sticker.url}
          </button>
        ))}
      </div>
    </div>
  );
}