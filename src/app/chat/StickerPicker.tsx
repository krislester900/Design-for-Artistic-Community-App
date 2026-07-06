import { useState, useMemo } from "react";
import { X, Search } from "lucide-react";

const STICKER_CATEGORIES = [
  {
    name: "Artiste",
    stickers: [
      { id: "art-1", name: "Pinceau", emoji: "🖌️", category: "art" },
      { id: "art-2", name: "Palette", emoji: "🎨", category: "art" },
      { id: "art-3", name: "Caméra", emoji: "📷", category: "art" },
      { id: "art-4", name: "Film", emoji: "🎬", category: "art" },
      { id: "art-5", name: "Micro", emoji: "🎤", category: "art" },
      { id: "art-6", name: "Notes", emoji: "🎵", category: "art" },
      { id: "art-7", name: "Studio", emoji: "🎧", category: "art" },
      { id: "art-8", name: "Crayon", emoji: "✏️", category: "art" },
      { id: "art-9", name: "Livres", emoji: "📚", category: "art" },
      { id: "art-10", name: "Étoile", emoji: "⭐", category: "art" },
      { id: "art-11", name: "Magique", emoji: "✨", category: "art" },
      { id: "art-12", name: "Inspiré", emoji: "💡", category: "art" },
    ],
  },
  {
    name: "Émotions",
    stickers: [
      { id: "emo-1", name: "Amour", emoji: "😍", category: "emotion" },
      { id: "emo-2", name: "Feu", emoji: "🔥", category: "emotion" },
      { id: "emo-3", name: "Clap", emoji: "👏", category: "emotion" },
      { id: "emo-4", name: "Rire", emoji: "😂", category: "emotion" },
      { id: "emo-5", name: "Cool", emoji: "😎", category: "emotion" },
      { id: "emo-6", name: "Wow", emoji: "🤯", category: "emotion" },
      { id: "emo-7", name: "Triste", emoji: "😢", category: "emotion" },
      { id: "emo-8", name: "Colère", emoji: "😡", category: "emotion" },
      { id: "emo-9", name: "Peur", emoji: "😱", category: "emotion" },
      { id: "emo-10", name: "Dormir", emoji: "😴", category: "emotion" },
      { id: "emo-11", name: "Malade", emoji: "🤒", category: "emotion" },
      { id: "emo-12", name: "Amoureux", emoji: "🥰", category: "emotion" },
    ],
  },
  {
    name: "Gestes",
    stickers: [
      { id: "gest-1", name: "Pouce haut", emoji: "👍", category: "gesture" },
      { id: "gest-2", name: "Pouce bas", emoji: "👎", category: "gesture" },
      { id: "gest-3", name: "Victoire", emoji: "✌️", category: "gesture" },
      { id: "gest-4", name: "Rock", emoji: "🤘", category: "gesture" },
      { id: "gest-5", name: "Corps", emoji: "💪", category: "gesture" },
      { id: "gest-6", name: "Prayer", emoji: "🙏", category: "gesture" },
      { id: "gest-7", name: "Salut", emoji: "👋", category: "gesture" },
      { id: "gest-8", name: "Main", emoji: "🖐️", category: "gesture" },
      { id: "gest-9", name: "Ok", emoji: "👌", category: "gesture" },
      { id: "gest-10", name: "Coeur", emoji: "🫶", category: "gesture" },
      { id: "gest-11", name: "Pointage", emoji: "👉", category: "gesture" },
      { id: "gest-12", name: "Paix", emoji: "☮️", category: "gesture" },
    ],
  },
  {
    name: "Objets",
    stickers: [
      { id: "obj-1", name: "Cadeau", emoji: "🎁", category: "object" },
      { id: "obj-2", name: "Diamant", emoji: "💎", category: "object" },
      { id: "obj-3", name: "Couronne", emoji: "👑", category: "object" },
      { id: "obj-4", name: "Épée", emoji: "⚔️", category: "object" },
      { id: "obj-5", name: "Bouclier", emoji: "🛡️", category: "object" },
      { id: "obj-6", name: "Trophée", emoji: "🏆", category: "object" },
      { id: "obj-7", name: "Médaille", emoji: "🥇", category: "object" },
      { id: "obj-8", name: "Bombe", emoji: "💣", category: "object" },
      { id: "obj-9", name: "Fusée", emoji: "🚀", category: "object" },
      { id: "obj-10", name: "Arc-en-ciel", emoji: "🌈", category: "object" },
      { id: "obj-11", name: "Foudre", emoji: "⚡", category: "object" },
      { id: "obj-12", name: "Snowflake", emoji: "❄️", category: "object" },
    ],
  },
  {
    name: "Nature",
    stickers: [
      { id: "nat-1", name: "Soleil", emoji: "☀️", category: "nature" },
      { id: "nat-2", name: "Lune", emoji: "🌙", category: "nature" },
      { id: "nat-3", name: "Étoile filante", emoji: "🌠", category: "nature" },
      { id: "nat-4", name: "Fleur", emoji: "🌸", category: "nature" },
      { id: "nat-5", name: "Rose", emoji: "🌹", category: "nature" },
      { id: "nat-6", name: "Tournesol", emoji: "🌻", category: "nature" },
      { id: "nat-7", name: "Arbre", emoji: "🌳", category: "nature" },
      { id: "nat-8", name: "Feuille", emoji: "🍃", category: "nature" },
      { id: "nat-9", name: "Pluie", emoji: "🌧️", category: "nature" },
      { id: "nat-10", name: "Neige", emoji: "🌨️", category: "nature" },
      { id: "nat-11", name: "Océan", emoji: "🌊", category: "nature" },
      { id: "nat-12", name: "Papillon", emoji: "🦋", category: "nature" },
    ],
  },
];

type StickerPickerProps = {
  onSelect: (stickerId: string, stickerEmoji: string) => void;
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
            onClick={() => { onSelect(sticker.id, sticker.emoji); onClose(); }}
            className="flex h-14 w-14 items-center justify-center rounded-xl text-3xl hover:bg-primary/10 transition-all hover:scale-110"
            title={sticker.name}
          >
            {sticker.emoji}
          </button>
        ))}
      </div>
    </div>
  );
}