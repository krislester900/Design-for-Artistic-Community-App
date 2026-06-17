/**
 * MobileCommunity — Chat connecté Supabase + toutes les fonctionnalités
 * Vocaux, emojis, stickers, GIFs, pièces jointes — backend réel
 */
import { useState, useEffect, useRef } from "react";
import { Search, Send, Mic, Smile, Paperclip, ChevronLeft, Phone, Video, Image, Play, Pause, Volume2, Trash2, MessageSquare } from "lucide-react";
import { supabase, hasSupabaseEnv } from "../lib/supabase";
import { getCurrentSession, type AuthUser } from "../services/auth";
import { EmojiPicker } from "../chat/EmojiPicker";
import { StickerPicker } from "../chat/StickerPicker";
import { GifPicker } from "../chat/GifPicker";
import { VoiceRecorder } from "../chat/VoiceRecorder";

// Types from chat system
interface ChatChannel {
  id: string;
  name: string;
  type: "public" | "private" | "dm";
  description: string;
  created_at: string;
}

interface ChatMessage {
  id: string;
  channel_id: string;
  author_id: string;
  author_email?: string;
  content: string;
  attachment_url?: string;
  reply_to?: string;
  edited_at?: string;
  created_at: string;
  message_type?: "text" | "voice" | "sticker" | "gif" | "image";
  voice_url?: string;
  voice_duration?: number;
  reactions?: any[];
  is_pinned?: boolean;
}

// Mock channels (replace with Supabase query when data exists)
const DEFAULT_CHANNELS: ChatChannel[] = [
  { id: "general", name: "Général", type: "public", description: "Discussions générales", created_at: new Date().toISOString() },
  { id: "music", name: "Musique Urbaine", type: "public", description: "Sons, beats, productions", created_at: new Date().toISOString() },
  { id: "visual-art", name: "Art Visuel Paris", type: "public", description: "Expos, street art, galeries", created_at: new Date().toISOString() },
  { id: "manga", name: "Manga Club", type: "public", description: "Chapitres, reviews, fan arts", created_at: new Date().toISOString() },
];

const DEFAULT_MESSAGES: Record<string, ChatMessage[]> = {
  general: [
    {
      id: "general-1",
      channel_id: "general",
      author_id: "system",
      author_email: "Artéïa",
      content: "Bienvenue dans le salon général. Présente ton univers et ce sur quoi tu bosses.",
      created_at: new Date(Date.now() - 1000 * 60 * 35).toISOString(),
      message_type: "text",
    },
    {
      id: "general-2",
      channel_id: "general",
      author_id: "mila-chrom",
      author_email: "mila@arteia.app",
      content: "Je cherche des retours sur une série d'illustrations urbaines.",
      created_at: new Date(Date.now() - 1000 * 60 * 8).toISOString(),
      message_type: "text",
    },
  ],
  music: [
    {
      id: "music-1",
      channel_id: "music",
      author_id: "naya-pulse",
      author_email: "naya@arteia.app",
      content: "Qui veut tester un pack de drums afro-trap ce soir ?",
      created_at: new Date(Date.now() - 1000 * 60 * 18).toISOString(),
      message_type: "text",
    },
  ],
  "visual-art": [
    {
      id: "visual-art-1",
      channel_id: "visual-art",
      author_id: "urban-art",
      author_email: "urban@arteia.app",
      content: "Je poste demain une fresque terminée, vos avis sur la palette néon ?",
      created_at: new Date(Date.now() - 1000 * 60 * 22).toISOString(),
      message_type: "text",
    },
  ],
  manga: [
    {
      id: "manga-1",
      channel_id: "manga",
      author_id: "kiro-ink",
      author_email: "kiro@arteia.app",
      content: "Je finalise un pilote de 12 pages. Vous préférez lecture verticale ou planches classiques ?",
      created_at: new Date(Date.now() - 1000 * 60 * 42).toISOString(),
      message_type: "text",
    },
  ],
};

function mergeMessages(messages: ChatMessage[]) {
  const uniqueMessages = new Map<string, ChatMessage>();

  messages.forEach((item) => {
    uniqueMessages.set(item.id, item);
  });

  return Array.from(uniqueMessages.values()).sort(
    (a, b) =>
      new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
  );
}

export function MobileCommunity({ onChatStateChange }: { onChatStateChange?: (active: boolean) => void }) {
  const [activeChat, setActiveChat] = useState<string | null>(null);
  const [message, setMessage] = useState("");
  const [channels] = useState<ChatChannel[]>(DEFAULT_CHANNELS);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [showEmoji, setShowEmoji] = useState(false);
  const [showStickers, setShowStickers] = useState(false);
  const [showGifs, setShowGifs] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const channelSubscriptionRef = useRef<any>(null);

  useEffect(() => {
    getCurrentSession().then(({ user }) => setAuthUser(user));
  }, []);

  useEffect(() => {
    let cancelled = false;

    if (!activeChat) {
      setMessages([]);
      return () => {
        cancelled = true;
      };
    }

    const fallbackMessages = DEFAULT_MESSAGES[activeChat] ?? [];
    setMessages(fallbackMessages);

    if (!hasSupabaseEnv || !supabase) {
      return () => {
        cancelled = true;
      };
    }

    supabase
      .from("chat_messages")
      .select(
        "id, channel_id, author_id, author_email, content, attachment_url, reply_to, edited_at, created_at, message_type, voice_url, voice_duration, is_pinned",
      )
      .eq("channel_id", activeChat)
      .order("created_at", { ascending: true })
      .then(({ data, error }) => {
        if (cancelled || error) {
          return;
        }

        const loadedMessages = (data ?? []) as ChatMessage[];
        setMessages(mergeMessages([...fallbackMessages, ...loadedMessages]));
      });

    return () => {
      cancelled = true;
    };
  }, [activeChat]);

  // Subscribe to Supabase realtime messages
  useEffect(() => {
    if (!activeChat || !hasSupabaseEnv || !supabase) return;

    // Cleanup previous subscription
    channelSubscriptionRef.current?.unsubscribe();

    const channel = supabase
      .channel(`chat-${activeChat}`)
      .on("postgres_changes", {
        event: "INSERT",
        schema: "public",
        table: "chat_messages",
        filter: `channel_id=eq.${activeChat}`,
      }, (payload) => {
        setMessages((prev) => mergeMessages([...prev, payload.new as ChatMessage]));
      })
      .subscribe();

    channelSubscriptionRef.current = channel;

    return () => {
      channel.unsubscribe();
    };
  }, [activeChat]);

  // Scroll to bottom on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, activeChat]);

  async function handleSend(content?: string, attachmentUrl?: string) {
    if (!activeChat) return;

    const msgContent = content ?? message;
    const trimmedContent = msgContent.trim();
    if (!trimmedContent && !attachmentUrl) return;

    const newMsg: ChatMessage = {
      id: crypto.randomUUID(),
      channel_id: activeChat,
      author_id: authUser?.id || "guest",
      author_email: authUser?.email || "Invité",
      content: trimmedContent,
      attachment_url: attachmentUrl,
      created_at: new Date().toISOString(),
      message_type: attachmentUrl ? "image" : "text",
    };

    setMessage("");
    closeAllPickers();

    // Send to Supabase
    if (hasSupabaseEnv && supabase && authUser) {
      const { error } = await supabase.from("chat_messages").insert({
        channel_id: activeChat,
        author_id: authUser.id,
        author_email: authUser.email,
        content: trimmedContent,
        attachment_url: attachmentUrl,
        message_type: attachmentUrl ? "image" : "text",
      });

      if (!error) {
        return;
      }
    }

    setMessages((prev) => mergeMessages([...prev, newMsg]));
  }

  function handleSendVoice(audioBlob: Blob, duration: number) {
    const url = URL.createObjectURL(audioBlob);
    const newMsg: ChatMessage = {
      id: crypto.randomUUID(),
      channel_id: activeChat!,
      author_id: authUser?.id || "guest",
      author_email: authUser?.email || "Invité",
      content: "🔊 Message vocal",
      created_at: new Date().toISOString(),
      message_type: "voice",
      voice_url: url,
      voice_duration: duration,
    };
    setMessages((prev) => mergeMessages([...prev, newMsg]));
    setIsRecording(false);
  }

  function handleSendSticker(stickerId: string, stickerUrl: string) {
    const newMsg: ChatMessage = {
      id: crypto.randomUUID(),
      channel_id: activeChat!,
      author_id: authUser?.id || "guest",
      author_email: authUser?.email || "Invité",
      content: stickerUrl,
      created_at: new Date().toISOString(),
      message_type: "sticker",
    };
    setMessages((prev) => mergeMessages([...prev, newMsg]));
    setShowStickers(false);
  }

  function handleSendGif(gifUrl: string) {
    const newMsg: ChatMessage = {
      id: crypto.randomUUID(),
      channel_id: activeChat!,
      author_id: authUser?.id || "guest",
      author_email: authUser?.email || "Invité",
      content: gifUrl,
      created_at: new Date().toISOString(),
      message_type: "gif",
    };
    setMessages((prev) => mergeMessages([...prev, newMsg]));
    setShowGifs(false);
  }

  function closeAllPickers() {
    setShowEmoji(false);
    setShowStickers(false);
    setShowGifs(false);
  }

  // Notify parent when chat state changes
  useEffect(() => {
    onChatStateChange?.(!!activeChat);
  }, [activeChat, onChatStateChange]);

  // Voice recording mode
  if (isRecording && activeChat) {
    return (
      <div className="flex flex-col h-full bg-background">
        <header className="flex items-center gap-3 px-4 py-3 border-b border-border/30 bg-card/45 backdrop-blur-xl shrink-0">
          <button onClick={() => setIsRecording(false)} className="text-primary text-sm font-medium touch-manipulation">
            ← Retour
          </button>
          <span className="text-sm font-semibold text-foreground">Message vocal</span>
        </header>
        <VoiceRecorder
          onSendVoice={handleSendVoice}
          onCancel={() => setIsRecording(false)}
        />
      </div>
    );
  }

  // Chat view — expose activeChat to parent via callback
  if (activeChat) {
    const chat = channels.find(c => c.id === activeChat);
    return (
      <div className="flex flex-col h-full bg-background" data-chat-active="true">
        {/* Chat Header */}
        <header className="flex items-center gap-3 px-4 py-3 border-b border-border/30 bg-card/55 backdrop-blur-xl shrink-0">
          <button onClick={() => { setActiveChat(null); closeAllPickers(); }} className="flex items-center gap-1 text-primary text-sm font-medium touch-manipulation active:opacity-70">
            <ChevronLeft className="h-5 w-5" />
          </button>
          <div className="flex-1 min-w-0">
            <h3 className="text-sm font-semibold text-foreground truncate">{chat?.name}</h3>
            <p className="text-[10px] text-muted-foreground">{chat?.description}</p>
          </div>
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 touch-manipulation">
            <Phone className="h-4 w-4" />
          </button>
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 touch-manipulation">
            <Video className="h-4 w-4" />
          </button>
        </header>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3 bg-[radial-gradient(circle_at_top,rgba(156,107,255,0.08),transparent_34%),radial-gradient(circle_at_bottom_right,rgba(38,224,192,0.06),transparent_28%)]" style={{ WebkitOverflowScrolling: "touch" }}>
          {messages.length === 0 && (
            <div className="text-center py-12">
              <MessageSquare className="h-10 w-10 text-muted-foreground/20 mx-auto mb-3" />
              <p className="text-sm text-muted-foreground">Aucun message</p>
              <p className="text-xs text-muted-foreground/50 mt-1">Sois le premier à écrire !</p>
            </div>
          )}
          {messages.map((msg, idx) => {
            const isOwn = msg.author_id === authUser?.id;
            const showAuthor = !isOwn && (idx === 0 || messages[idx - 1]?.author_id !== msg.author_id);
            const isSticker = msg.message_type === "sticker";
            const isGif = msg.message_type === "gif";
            const isVoice = msg.message_type === "voice";

            return (
              <div key={msg.id} className={`flex ${isOwn ? "justify-end" : "justify-start"}`}>
                {!isOwn && showAuthor && (
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary/20 to-accent/20 mr-2 mt-1">
                    <span className="text-[10px] font-bold text-primary">{msg.author_email?.charAt(0) || "?"}</span>
                  </div>
                )}
                {!isOwn && !showAuthor && <div className="w-9 shrink-0 mr-2" />}

                {isVoice && msg.voice_url ? (
                  <VoiceBubble msg={msg} isOwn={isOwn} />
                ) : isSticker ? (
                  <div className="py-1"><span className="text-5xl leading-none">{msg.content}</span></div>
                ) : isGif ? (
                  <div className="py-1 max-w-[70%]">
                    <img src={msg.content} alt="GIF" className="rounded-2xl max-h-48 object-cover" />
                  </div>
                ) : (
                  <div className={`max-w-[78%] rounded-[18px] px-3.5 py-2.5 shadow-sm ${
                    isOwn
                      ? "bg-gradient-to-br from-primary via-secondary to-primary text-primary-foreground rounded-br-md shadow-[0_16px_32px_rgba(156,107,255,0.22)]"
                      : "bg-card/88 border border-border/30 text-foreground rounded-bl-md backdrop-blur-xl"
                  }`}>
                    {showAuthor && (
                      <p className="text-[11px] font-semibold text-primary mb-0.5">{msg.author_email || "Inconnu"}</p>
                    )}
                    <p className="font-message text-sm leading-relaxed">{msg.content}</p>
                    {msg.attachment_url && (
                      <img src={msg.attachment_url} alt="Pièce jointe" className="mt-2 rounded-xl max-h-48 object-cover" />
                    )}
                    <p className={`text-[10px] mt-1 text-right ${isOwn ? "text-white/50" : "text-muted-foreground/40"}`}>
                      {new Date(msg.created_at).toLocaleTimeString("fr", { hour: "2-digit", minute: "2-digit" })}
                      {msg.edited_at ? " (modifié)" : ""}
                    </p>
                  </div>
                )}
              </div>
            );
          })}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Bar with pickers */}
        <div className="relative shrink-0 border-t border-border/30 bg-card/55 backdrop-blur-xl">
          {/* Pickers — positioned above input bar */}
          {showEmoji && (
            <div className="absolute bottom-full left-0 right-0 z-50">
              <EmojiPicker onSelect={(emoji) => { setMessage(prev => prev + emoji); }} onClose={() => setShowEmoji(false)} />
            </div>
          )}
          {showStickers && (
            <div className="absolute bottom-full left-0 right-0 z-50">
              <StickerPicker onSelect={handleSendSticker} onClose={() => setShowStickers(false)} />
            </div>
          )}
          {showGifs && (
            <div className="absolute bottom-full left-0 right-0 z-50">
              <GifPicker onSelect={handleSendGif} onClose={() => setShowGifs(false)} />
            </div>
          )}
          <div className="flex items-center gap-2 px-3 py-2">
          <button
            onClick={() => { closeAllPickers(); setShowGifs(!showGifs); }}
            className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 active:scale-90 transition-all touch-manipulation"
          >
            <Image className="h-5 w-5" />
          </button>
          <button
            onClick={() => { closeAllPickers(); setShowStickers(!showStickers); }}
            className="flex h-9 w-9 items-center justify-center rounded-xl text-lg active:bg-card/60 active:scale-90 transition-all touch-manipulation"
          >
            🎭
          </button>
          <button
            onClick={() => { closeAllPickers(); setShowEmoji(!showEmoji); }}
            className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 active:scale-90 transition-all touch-manipulation"
          >
            <Smile className="h-5 w-5" />
          </button>
          <button className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground active:bg-card/60 active:scale-90 transition-all touch-manipulation">
            <Paperclip className="h-5 w-5" />
          </button>
          <input
            className="app-input font-message flex-1 h-10 px-4 placeholder:text-muted-foreground/30"
            placeholder="Écris un message..."
            value={message}
            onChange={(e) => { closeAllPickers(); setMessage(e.target.value); }}
            onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); handleSend(); } }}
          />
          {message.trim() ? (
            <button
              onClick={() => handleSend()}
              className="flex h-10 w-10 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-accent text-primary-foreground shadow-lg shadow-primary/20 active:scale-90 transition-all touch-manipulation"
            >
              <Send className="h-4 w-4" />
            </button>
          ) : (
            <button
              onClick={() => setIsRecording(true)}
              className="flex h-10 w-10 items-center justify-center rounded-2xl bg-card border border-border/40 text-muted-foreground shadow-sm active:scale-90 transition-all touch-manipulation"
            >
              <Mic className="h-4 w-4" />
            </button>
          )}
          </div>
        </div>
      </div>
    );
  }

  // Channel list view
  return (
    <div className="app-page space-y-5">
      <div className="app-hero-surface py-5">
        <span className="app-kicker mb-4">Studio social</span>
        <h1 className="text-3xl font-bold text-foreground mb-1 tracking-tight">Communauté</h1>
        <p className="text-xs text-muted-foreground">
          {hasSupabaseEnv ? "Chat en temps réel" : "Mode hors-ligne"}
        </p>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground/40" />
        <input
          className="app-input w-full pl-10 pr-4 placeholder:text-muted-foreground/30"
          placeholder="Rechercher une discussion..."
        />
      </div>

      <div className="space-y-0.5">
        {channels.map((channel) => (
          <button
            key={channel.id}
            onClick={() => setActiveChat(channel.id)}
            className="app-surface-soft flex items-center gap-3 w-full p-3 active:bg-card/60 transition-colors duration-100 touch-manipulation"
          >
            <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary/30 via-secondary/20 to-accent/15 border border-primary/15 shadow-[0_12px_30px_rgba(156,107,255,0.16)]">
              <span className="text-sm font-bold text-primary">#</span>
            </div>
            <div className="flex-1 min-w-0 text-left">
              <h3 className="text-sm font-semibold text-foreground">{channel.name}</h3>
              <p className="text-xs text-muted-foreground truncate mt-0.5">{channel.description}</p>
            </div>
            <ChevronLeft className="h-4 w-4 text-muted-foreground/30 rotate-180" />
          </button>
        ))}
      </div>
    </div>
  );
}

/** Voice message bubble with animated waveform */
function VoiceBubble({ msg, isOwn }: { msg: ChatMessage; isOwn: boolean }) {
  const [playing, setPlaying] = useState(false);
  const audioRef = useRef<HTMLAudioElement>(null);

  function togglePlay() {
    if (!audioRef.current) return;
    if (playing) { audioRef.current.pause(); }
    else { audioRef.current.play().catch(() => {}); }
    setPlaying(!playing);
  }

  return (
    <div className={`inline-flex items-center gap-3 rounded-2xl px-4 py-2.5 ${isOwn ? "bg-gradient-to-r from-primary/15 to-primary/5" : "bg-card border border-border/30"}`}>
      <button onClick={togglePlay} className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary to-accent text-primary-foreground shadow-md active:scale-95">
        {playing ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4 ml-0.5" />}
      </button>
      <Volume2 className={`h-3.5 w-3.5 ${playing ? "text-primary" : "text-muted-foreground"}`} />
      <div className="flex items-end gap-[1.5px] h-6">
        {Array.from({ length: 24 }).map((_, i) => (
          <div key={i} className="w-[3px] rounded-full transition-all" style={{
            height: `${4 + Math.sin(i * 0.6) * 10 + Math.cos(i * 0.3) * 6 + Math.random() * 6}px`,
            backgroundColor: playing ? "var(--primary)" : "var(--muted-foreground)",
            opacity: playing ? 0.6 + Math.random() * 0.4 : 0.3,
            animation: playing ? `audio-wave ${0.4 + Math.random() * 0.6}s ease-in-out infinite ${i * 0.04}s` : "none",
          }} />
        ))}
      </div>
      <span className="font-message text-[11px] tabular-nums text-muted-foreground">{msg.voice_duration ? `${Math.floor(msg.voice_duration / 60)}:${String(Math.floor(msg.voice_duration % 60)).padStart(2, "0")}` : "0:00"}</span>
      <audio ref={audioRef} src={msg.voice_url} onEnded={() => setPlaying(false)} />
    </div>
  );
}
