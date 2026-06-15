/**
 * MobileNotifications — Système de notifications complexe
 */
import { useState } from "react";
import { Bell, Heart, MessageCircle, UserPlus, Star, TrendingUp, Clock, Check, CheckCheck, Filter, ChevronRight, X } from "lucide-react";

interface Notification {
  id: string;
  type: "like" | "comment" | "follow" | "mention" | "achievement" | "trending";
  user: string;
  avatar: string;
  content: string;
  time: string;
  read: boolean;
  emoji: string;
  gradient: string;
}

const NOTIFICATIONS: Notification[] = [
  { id: "1", type: "like", user: "ArtDiva", avatar: "🎨", content: "a aimé votre œuvre Portrait Neon", time: "Il y a 2min", read: false, emoji: "❤️", gradient: "from-red-500 to-pink-500" },
  { id: "2", type: "comment", user: "MusicPro", avatar: "🎵", content: "a commenté Beat Session : \"Incroyable !\"", time: "Il y a 15min", read: false, emoji: "💬", gradient: "from-violet-500 to-purple-500" },
  { id: "3", type: "follow", user: "MangaKing", avatar: "📚", content: "a commencé à vous suivre", time: "Il y a 1h", read: false, emoji: "👤", gradient: "from-blue-500 to-cyan-500" },
  { id: "4", type: "achievement", user: "Système", avatar: "🏆", content: "Vous avez atteint 100 likes !", time: "Il y a 2h", read: true, emoji: "🏆", gradient: "from-amber-500 to-orange-500" },
  { id: "5", type: "trending", user: "Tendance", avatar: "🔥", content: "Motion Loop est en tendance !", time: "Il y a 3h", read: true, emoji: "🔥", gradient: "from-red-500 to-orange-500" },
  { id: "6", type: "like", user: "FilmArt", avatar: "🎬", content: "a aimé Court-Métrage", time: "Il y a 5h", read: true, emoji: "❤️", gradient: "from-emerald-500 to-teal-500" },
  { id: "7", type: "comment", user: "PoèteNuit", avatar: "✍️", content: "a commenté Poème Urbain : \"Magnifique\"", time: "Il y a 8h", read: true, emoji: "💬", gradient: "from-rose-500 to-pink-500" },
  { id: "8", type: "mention", user: "UrbanArt", avatar: "🏙️", content: "vous a mentionné dans un post", time: "Il y a 1j", read: true, emoji: "📢", gradient: "from-cyan-500 to-blue-500" },
];

const FILTERS = ["Toutes", "Non lues", "Likes", "Commentaires", "Follows"];

export function MobileNotifications() {
  const [activeFilter, setActiveFilter] = useState("Toutes");
  const [notifications, setNotifications] = useState(NOTIFICATIONS);

  const filtered = notifications.filter(n => {
    if (activeFilter === "Non lues") return !n.read;
    if (activeFilter === "Likes") return n.type === "like";
    if (activeFilter === "Commentaires") return n.type === "comment";
    if (activeFilter === "Follows") return n.type === "follow";
    return true;
  });

  const markAllRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  };

  const markRead = (id: string) => {
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n));
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <div className="px-4 py-6 space-y-5 pb-24">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground" style={{ fontFamily: "'Outfit', sans-serif" }}>Notifications</h1>
          <p className="text-xs text-muted-foreground mt-0.5">{unreadCount} non lues</p>
        </div>
        <button
          onClick={markAllRead}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-primary/10 text-primary text-xs font-medium active:scale-95 transition-all touch-manipulation"
        >
          <CheckCheck className="h-3.5 w-3.5" />
          Tout lire
        </button>
      </div>

      {/* Filters */}
      <div className="flex gap-2 overflow-x-auto scrollbar-hide">
        {FILTERS.map((filter) => (
          <button
            key={filter}
            onClick={() => setActiveFilter(filter)}
            className={`shrink-0 px-4 py-1.5 rounded-full text-xs font-medium transition-all duration-150 active:scale-95 touch-manipulation ${
              activeFilter === filter
                ? "bg-primary/15 border border-primary/30 text-primary"
                : "bg-card border border-border/40 text-muted-foreground"
            }`}
          >
            {filter}
          </button>
        ))}
      </div>

      {/* Notifications List */}
      <div className="space-y-2">
        {filtered.map((notif) => (
          <div
            key={notif.id}
            onClick={() => markRead(notif.id)}
            className={`flex items-start gap-3 p-3 rounded-2xl border transition-all duration-100 active:scale-[0.98] touch-manipulation ${
              notif.read
                ? "bg-card/40 border-border/20"
                : "bg-card border-primary/20 shadow-sm"
            }`}
          >
            <div className={`h-10 w-10 rounded-full bg-gradient-to-br ${notif.gradient} flex items-center justify-center shrink-0`}>
              <span className="text-lg">{notif.emoji}</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm text-foreground">
                <span className="font-semibold">{notif.user}</span>{" "}
                <span className="text-muted-foreground">{notif.content}</span>
              </p>
              <p className="text-[10px] text-muted-foreground/50 mt-1">{notif.time}</p>
            </div>
            {!notif.read && (
              <div className="h-2.5 w-2.5 rounded-full bg-primary shrink-0 mt-1.5" />
            )}
          </div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="text-center py-12">
          <Bell className="h-10 w-10 text-muted-foreground/20 mx-auto mb-3" />
          <p className="text-sm text-muted-foreground">Aucune notification</p>
          <p className="text-xs text-muted-foreground/50 mt-1">Tu es à jour !</p>
        </div>
      )}
    </div>
  );
}