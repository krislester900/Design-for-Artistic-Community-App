/**
 * MobileCommunity — Écran Communauté (Spec v2)
 * Liste de chats + interface chat complète
 */
import { useState } from "react";
import { Search, Send, Mic, Smile, Paperclip, MessageSquare, ChevronLeft, Phone, Video } from "lucide-react";

interface ChatRoom {
  id: string;
  name: string;
  lastMessage: string;
  time: string;
  unread: number;
  online: boolean;
  avatar: string;
}

interface Message {
  id: string;
  author: string;
  content: string;
  isOwn: boolean;
  time: string;
}

const CHATS: ChatRoom[] = [
  { id: "1", name: "Musique Urbaine", lastMessage: "Nouveau son dispo ! 🎵", time: "2m", unread: 3, online: true, avatar: "M" },
  { id: "2", name: "Art Visuel Paris", lastMessage: "Expo ce weekend au 104", time: "1h", unread: 0, online: false, avatar: "A" },
  { id: "3", name: "Manga Club", lastMessage: "Chapitre 42 analysé 📖", time: "3h", unread: 5, online: true, avatar: "M" },
  { id: "4", name: "Films Indés", lastMessage: "Projection privée demain", time: "5h", unread: 1, online: false, avatar: "F" },
  { id: "5", name: "Littérature Nocturne", lastMessage: "Nouveau poème publié", time: "1j", unread: 0, online: true, avatar: "L" },
];

const MESSAGES: Message[] = [
  { id: "1", author: "DJ Katalyst", content: "Salut ! Super morceau 🎵", isOwn: false, time: "14:30" },
  { id: "2", author: "DJ Katalyst", content: "Merci ! J'ai bossé dessus toute la semaine", isOwn: false, time: "14:31" },
  { id: "3", author: "DJ Katalyst", content: "Tu veux écouter la version longue ? Elle fait 6 minutes", isOwn: false, time: "14:32" },
  { id: "4", author: "Moi", content: "Grave ! Envoie la version longue 🔥", isOwn: true, time: "14:33" },
  { id: "5", author: "Moi", content: "Le mix est vraiment propre, les basses sont intenses", isOwn: true, time: "14:34" },
  { id: "6", author: "DJ Katalyst", content: "Merci mec ! Je l'ai masterisé hier soir. Ça sort sur Spotify la semaine prochaine", isOwn: false, time: "14:35" },
];

export function MobileCommunity() {
  const [activeChat, setActiveChat] = useState<string | null>(null);
  const [message, setMessage] = useState("");

  if (activeChat) {
    const chat = CHATS.find(c => c.id === activeChat);
    return (
      <div className="flex flex-col h-full bg-background">
        {/* Chat Header */}
        <header className="flex items-center gap-3 px-4 py-3 border-b border-border/30 bg-background/95 backdrop-blur-xl shrink-0">
          <button onClick={() => setActiveChat(null)} className="flex items-center gap-1 text-primary text-sm font-medium touch-manipulation active:opacity-70">
            <ChevronLeft className="h-5 w-5" />
          </button>
          <div className="relative">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-primary/20 to-primary/5 border border-primary/10">
              <span className="text-xs font-bold text-primary">{chat?.avatar}</span>
            </div>
            {chat?.online && (
              <div className="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full bg-green-500 border-2 border-background" />
            )}
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-sm font-semibold text-foreground truncate">{chat?.name}</h3>
            {chat?.online && <p className="text-[10px] text-green-400 font-medium">En ligne</p>}
          </div>
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 touch-manipulation">
            <Phone className="h-4 w-4" />
          </button>
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 touch-manipulation">
            <Video className="h-4 w-4" />
          </button>
        </header>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3" style={{ WebkitOverflowScrolling: "touch" }}>
          {MESSAGES.map((msg, idx) => {
            const showAuthor = !msg.isOwn && (idx === 0 || MESSAGES[idx - 1].author !== msg.author);
            return (
              <div key={msg.id} className={`flex ${msg.isOwn ? "justify-end" : "justify-start"} animate-message-enter`}>
                {!msg.isOwn && showAuthor && (
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary/20 to-accent/20 mr-2 mt-1">
                    <span className="text-[10px] font-bold text-primary">{msg.author.charAt(0)}</span>
                  </div>
                )}
                {!msg.isOwn && !showAuthor && <div className="w-9 shrink-0 mr-2" />}
                <div className={`max-w-[78%] rounded-[18px] px-3.5 py-2.5 shadow-sm ${
                  msg.isOwn
                    ? "bg-gradient-to-br from-primary to-primary/90 text-primary-foreground rounded-br-md"
                    : "bg-card border border-border/30 text-foreground rounded-bl-md"
                }`}>
                  {showAuthor && !msg.isOwn && (
                    <p className="text-[11px] font-semibold text-primary mb-0.5">{msg.author}</p>
                  )}
                  <p className="text-sm leading-relaxed">{msg.content}</p>
                  <p className={`text-[10px] mt-1 text-right ${msg.isOwn ? "text-white/50" : "text-muted-foreground/40"}`}>
                    {msg.time}
                  </p>
                </div>
              </div>
            );
          })}
        </div>

        {/* Input Bar */}
        <div className="flex items-center gap-2 px-3 py-2 border-t border-border/30 bg-background/95 backdrop-blur-xl shrink-0">
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 active:scale-90 transition-all touch-manipulation">
            <Smile className="h-5 w-5" />
          </button>
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 active:scale-90 transition-all touch-manipulation">
            <Paperclip className="h-5 w-5" />
          </button>
          <input
            className="flex-1 h-10 rounded-2xl border border-border/50 bg-card/60 px-4 text-sm text-foreground outline-none focus:border-primary/50 focus:ring-2 focus:ring-primary/5 transition-all placeholder:text-muted-foreground/30"
            placeholder="Écris un message..."
            value={message}
            onChange={(e) => setMessage(e.target.value)}
          />
          <button className={`flex h-10 w-10 items-center justify-center rounded-2xl active:scale-90 transition-all touch-manipulation shadow-sm ${
            message.trim()
              ? "bg-gradient-to-br from-primary to-accent text-primary-foreground shadow-primary/20"
              : "bg-card border border-border/40 text-muted-foreground"
          }`}>
            {message.trim() ? <Send className="h-4 w-4" /> : <Mic className="h-4 w-4" />}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="px-4 py-6 space-y-5 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-foreground mb-1">Communauté</h1>
        <p className="text-xs text-muted-foreground">Discute avec d'autres créateurs</p>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground/40" />
        <input
          className="w-full h-11 pl-10 pr-4 rounded-xl border border-border/50 bg-card/60 text-sm text-foreground outline-none placeholder:text-muted-foreground/30 focus:border-primary/50 transition-all"
          placeholder="Rechercher une discussion..."
        />
      </div>

      {/* Chat List */}
      <div className="space-y-0.5">
        {CHATS.map((chat) => (
          <button
            key={chat.id}
            onClick={() => setActiveChat(chat.id)}
            className="flex items-center gap-3 w-full p-3 rounded-2xl active:bg-card/60 transition-colors duration-100 touch-manipulation"
          >
            <div className="relative shrink-0">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-card border border-border/30">
                <span className="text-sm font-bold text-primary">{chat.avatar}</span>
              </div>
              {chat.online && (
                <div className="absolute bottom-0.5 right-0.5 h-3 w-3 rounded-full bg-green-500 border-2 border-background" />
              )}
            </div>
            <div className="flex-1 min-w-0 text-left">
              <div className="flex items-center justify-between gap-2">
                <h3 className="text-sm font-semibold text-foreground truncate">{chat.name}</h3>
                <span className="text-[10px] text-muted-foreground/50 shrink-0">{chat.time}</span>
              </div>
              <div className="flex items-center justify-between gap-2 mt-0.5">
                <p className="text-xs text-muted-foreground truncate">{chat.lastMessage}</p>
                {chat.unread > 0 && (
                  <span className="flex items-center justify-center h-5 min-w-[20px] rounded-full bg-primary text-[10px] font-bold text-primary-foreground px-1.5 shrink-0">
                    {chat.unread}
                  </span>
                )}
              </div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}