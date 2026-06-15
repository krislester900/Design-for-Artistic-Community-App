/** MobileCommunity — Chat et discussions communautaires */
import { useState } from "react";
import { Send, Mic, Smile, Paperclip, MessageSquare } from "lucide-react";

const MOCK_CHATS = [
  { id: "1", name: "Musique Urbaine", lastMessage: "Nouveau son dispo ! 🎵", time: "2m", unread: 3, online: true },
  { id: "2", name: "Art Visuel Paris", lastMessage: "Expo ce weekend au 104", time: "1h", unread: 0, online: false },
  { id: "3", name: "Manga Club", lastMessage: "Chapitre 42 analysé 📖", time: "3h", unread: 5, online: true },
  { id: "4", name: "Films Indés", lastMessage: "Projection privée demain", time: "5h", unread: 1, online: false },
];

const MOCK_MESSAGES = [
  { id: "1", author: "Moi", content: "Salut ! Super morceau 🎵", isOwn: true, time: "14:30" },
  { id: "2", author: "DJ Katalyst", content: "Merci ! J'ai bossé dessus toute la semaine", isOwn: false, time: "14:31" },
  { id: "3", author: "DJ Katalyst", content: "Tu veux écouter la version longue ?", isOwn: false, time: "14:32" },
  { id: "4", author: "Moi", content: "Grave ! Envoie !!!", isOwn: true, time: "14:33" },
];

export function MobileCommunity() {
  const [activeChat, setActiveChat] = useState<string | null>(null);
  const [message, setMessage] = useState("");

  if (activeChat) {
    const chat = MOCK_CHATS.find(c => c.id === activeChat);
    return (
      <div className="flex flex-col h-full">
        {/* Chat header */}
        <div className="flex items-center gap-3 px-4 py-3 border-b border-border/30 bg-background/95 backdrop-blur-xl">
          <button onClick={() => setActiveChat(null)} className="text-primary text-sm font-medium touch-manipulation">
            ← Retour
          </button>
          <div className="flex items-center gap-2">
            <div className="relative">
              <div className="h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center">
                <MessageSquare className="h-4 w-4 text-primary" />
              </div>
              {chat?.online && <div className="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full bg-green-500 border-2 border-background" />}
            </div>
            <span className="font-semibold text-sm text-foreground">{chat?.name}</span>
          </div>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3" style={{ WebkitOverflowScrolling: "touch" }}>
          {MOCK_MESSAGES.map((msg) => (
            <div key={msg.id} className={`flex ${msg.isOwn ? "justify-end" : "justify-start"}`}>
              <div className={`max-w-[80%] rounded-2xl px-4 py-2.5 ${
                msg.isOwn
                  ? "bg-gradient-to-br from-primary to-accent text-primary-foreground rounded-br-md"
                  : "bg-card/80 border border-border/30 rounded-bl-md"
              }`}>
                {!msg.isOwn && <p className="text-[10px] font-semibold text-primary mb-0.5">{msg.author}</p>}
                <p className="text-sm leading-relaxed">{msg.content}</p>
                <p className={`text-[10px] mt-1 ${msg.isOwn ? "text-white/60" : "text-muted-foreground"}`}>{msg.time}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Chat input */}
        <div className="flex items-center gap-2 px-3 py-2 border-t border-border/30 bg-background/95 backdrop-blur-xl">
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 touch-manipulation">
            <Smile className="h-5 w-5" />
          </button>
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 touch-manipulation">
            <Paperclip className="h-5 w-5" />
          </button>
          <input
            className="flex-1 h-10 rounded-2xl border border-border/50 bg-card/60 px-4 text-sm text-foreground outline-none focus:border-primary/50 transition-all placeholder:text-muted-foreground/40"
            placeholder="Écris un message..."
            value={message}
            onChange={(e) => setMessage(e.target.value)}
          />
          {message.trim() ? (
            <button className="flex h-10 w-10 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-accent text-primary-foreground shadow-lg active:scale-95 touch-manipulation">
              <Send className="h-4 w-4" />
            </button>
          ) : (
            <button className="flex h-10 w-10 items-center justify-center rounded-2xl bg-card/60 text-muted-foreground active:scale-95 touch-manipulation">
              <Mic className="h-4 w-4" />
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="px-4 py-6 space-y-4 pb-20">
      <div>
        <h1 className="text-2xl font-bold text-foreground mb-1">Communauté</h1>
        <p className="text-xs text-muted-foreground">Discute avec d'autres créateurs</p>
      </div>

      {/* Search */}
      <div className="relative">
        <input
          className="w-full h-10 rounded-2xl border border-border/50 bg-card/60 pl-4 pr-4 text-sm text-foreground outline-none focus:border-primary/50 placeholder:text-muted-foreground/40"
          placeholder="Rechercher une discussion..."
        />
      </div>

      {/* Chat list */}
      <div className="space-y-1">
        {MOCK_CHATS.map((chat) => (
          <button
            key={chat.id}
            onClick={() => setActiveChat(chat.id)}
            className="flex items-center gap-3 w-full p-3 rounded-2xl active:bg-card/60 transition-all touch-manipulation"
          >
            <div className="relative">
              <div className="h-11 w-11 rounded-full bg-card border border-border/30 flex items-center justify-center">
                <MessageSquare className="h-5 w-5 text-muted-foreground" />
              </div>
              {chat.online && <div className="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-green-500 border-2 border-background" />}
            </div>
            <div className="flex-1 min-w-0 text-left">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-semibold text-foreground truncate">{chat.name}</h3>
                <span className="text-[10px] text-muted-foreground shrink-0 ml-2">{chat.time}</span>
              </div>
              <p className="text-xs text-muted-foreground truncate">{chat.lastMessage}</p>
            </div>
            {chat.unread > 0 && (
              <div className="h-5 min-w-[20px] flex items-center justify-center rounded-full bg-primary text-[10px] font-bold text-primary-foreground px-1.5">
                {chat.unread}
              </div>
            )}
          </button>
        ))}
      </div>
    </div>
  );
}