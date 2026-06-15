import { Trash2, Edit2, Reply, Check, X, SmilePlus, Pin, Play, Pause, Volume2 } from "lucide-react";
import { format } from "date-fns";
import { fr } from "date-fns/locale";
import { useState, useRef, useCallback } from "react";
import type { ChatMessage as ChatMessageType, MessageReaction } from "./chat-types";
import { EmojiPicker } from "./EmojiPicker";

type ChatMessageProps = {
  message: ChatMessageType;
  isOwn: boolean;
  onDelete: (id: string) => void;
  onEdit: (id: string, content: string) => void;
  onReply: (id: string) => void;
  onReact?: (messageId: string, emoji: string) => void;
  onPin?: (messageId: string) => void;
  showAuthor?: boolean;
};

const QUICK_REACTIONS = ["👍", "❤️", "🔥", "😂", "😍", "🎉"];

export function ChatMessage({
  message,
  isOwn,
  onDelete,
  onEdit,
  onReply,
  onReact,
  onPin,
  showAuthor = true,
}: ChatMessageProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [editContent, setEditContent] = useState(message.content);
  const [showReactionPicker, setShowReactionPicker] = useState(false);
  const [isPlaying, setIsPlaying] = useState(false);
  const audioRef = useRef<HTMLAudioElement>(null);
  const reactionPickerRef = useRef<HTMLDivElement>(null);

  const time = (() => {
    try {
      return format(new Date(message.created_at), "HH:mm", { locale: fr });
    } catch {
      return "";
    }
  })();

  const date = (() => {
    try {
      return format(new Date(message.created_at), "dd/MM/yyyy", { locale: fr });
    } catch {
      return "";
    }
  })();

  function handleSaveEdit() {
    if (editContent.trim() && editContent !== message.content) {
      onEdit(message.id, editContent.trim());
    }
    setIsEditing(false);
  }

  function handleCancelEdit() {
    setEditContent(message.content);
    setIsEditing(false);
  }

  function toggleAudioPlayback() {
    if (!audioRef.current) return;
    if (isPlaying) {
      audioRef.current.pause();
    } else {
      audioRef.current.play();
    }
    setIsPlaying(!isPlaying);
  }

  const formatVoiceDuration = useCallback((seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${s.toString().padStart(2, "0")}`;
  }, []);

  function handleReaction(emoji: string) {
    onReact?.(message.id, emoji);
    setShowReactionPicker(false);
  }

  // Group reactions by emoji
  const groupedReactions = (() => {
    if (!message.reactions || message.reactions.length === 0) return [];
    const map = new Map<string, { count: number; users: string[]; reaction: MessageReaction }>();
    for (const r of message.reactions) {
      const existing = map.get(r.emoji);
      if (existing) {
        existing.count++;
        existing.users.push(r.user_id);
      } else {
        map.set(r.emoji, { count: 1, users: [r.user_id], reaction: r });
      }
    }
    return Array.from(map.entries());
  })();

  // Render content with basic markdown
  function renderContent(text: string) {
    // Bold
    let parts = text.split(/(\*\*.*?\*\*)/g);
    return parts.map((part, i) => {
      if (part.startsWith("**") && part.endsWith("**")) {
        return <strong key={i} className="font-semibold">{part.slice(2, -2)}</strong>;
      }
      // Italic
      const italicParts = part.split(/(\*.*?\*)/g);
      return italicParts.map((ip, j) => {
        if (ip.startsWith("*") && ip.endsWith("*") && ip.length > 2) {
          return <em key={`${i}-${j}`} className="italic">{ip.slice(1, -1)}</em>;
        }
        // Code
        const codeParts = ip.split(/(`.*?`)/g);
        return codeParts.map((cp, k) => {
          if (cp.startsWith("`") && cp.endsWith("`")) {
            return (
              <code key={`${i}-${j}-${k}`} className="rounded-md bg-muted/60 px-1.5 py-0.5 text-[13px] font-mono">
                {cp.slice(1, -1)}
              </code>
            );
          }
          return cp;
        });
      });
    });
  }

  // Determine message type for rendering
  const isSticker = message.message_type === "sticker";
  const isVoice = message.message_type === "voice";
  const isGif = message.message_type === "gif";
  const isImage = message.message_type === "image" || (message.attachment_url && /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(message.attachment_url));

  return (
    <div
      className={`group relative flex gap-3 px-6 py-1.5 transition-colors hover:bg-card/30 message-enter chat-message-hover`}
    >
      {/* Avatar */}
      {showAuthor && (
      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary/20 to-primary/5 text-xs font-bold uppercase text-primary ring-2 ring-background transition-transform group-hover:scale-110">
          {message.author_email?.charAt(0) ?? "?"}
        </div>
      )}
      {!showAuthor && <div className="w-9 shrink-0" />}

      {/* Content */}
      <div className="min-w-0 flex-1">
        {/* Header with author and time */}
        {showAuthor && (
          <div className="flex items-baseline gap-2 mb-0.5">
            <span className={`text-sm font-semibold ${isOwn ? "text-primary" : "text-foreground"}`}>
              {message.author_email ?? "Inconnu"}
            </span>
            <span className="text-[10px] text-muted-foreground/50" title={date}>
              {time}
            </span>
            {message.is_pinned && (
              <Pin className="h-3 w-3 text-amber-500" fill="currentColor" />
            )}
            {message.edited_at && (
              <span className="text-[10px] text-muted-foreground/40">(modifié)</span>
            )}

            {/* Actions (visible on hover) */}
            {!isEditing && (
              <div className="ml-auto flex items-center gap-0.5 opacity-0 transition-opacity group-hover:opacity-100">
                {/* Quick reactions */}
                {onReact && (
                  <div className="relative" ref={reactionPickerRef}>
                    <button
                      onClick={() => setShowReactionPicker(!showReactionPicker)}
                      className="flex h-6 w-6 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-card/60 hover:text-primary"
                      title="Réagir"
                    >
                      <SmilePlus className="h-3.5 w-3.5" />
                    </button>
                    {showReactionPicker && (
                      <div className="absolute bottom-full right-0 mb-1 flex items-center gap-0.5 rounded-xl border border-border bg-card/95 px-2 py-1.5 shadow-xl backdrop-blur-xl z-50">
                        {QUICK_REACTIONS.map((emoji) => (
                          <button
                            key={emoji}
                            onClick={() => handleReaction(emoji)}
                            className="flex h-7 w-7 items-center justify-center rounded-lg text-base hover:bg-primary/10 hover:scale-125 transition-all"
                          >
                            {emoji}
                          </button>
                        ))}
                        <div className="ml-1 border-l border-border pl-1 relative">
                          <EmojiPicker
                            onSelect={(emoji) => handleReaction(emoji)}
                            onClose={() => setShowReactionPicker(false)}
                          />
                          <button
                            onClick={() => setShowReactionPicker(!showReactionPicker)}
                            className="flex h-7 w-7 items-center justify-center rounded-lg text-muted-foreground hover:bg-primary/10 transition-all"
                          >
                            <SmilePlus className="h-3.5 w-3.5" />
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                )}
                <button
                  onClick={() => onReply(message.id)}
                  className="flex h-6 w-6 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-card/60 hover:text-primary"
                  title="Répondre"
                >
                  <Reply className="h-3.5 w-3.5" />
                </button>
                {onPin && (
                  <button
                    onClick={() => onPin(message.id)}
                    className="flex h-6 w-6 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-card/60 hover:text-amber-500"
                    title={message.is_pinned ? "Désépingler" : "Épingler"}
                  >
                    <Pin className="h-3.5 w-3.5" />
                  </button>
                )}
                {isOwn && (
                  <>
                    <button
                      onClick={() => setIsEditing(true)}
                      className="flex h-6 w-6 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-card/60 hover:text-primary"
                      title="Modifier"
                    >
                      <Edit2 className="h-3.5 w-3.5" />
                    </button>
                    <button
                      onClick={() => onDelete(message.id)}
                      className="flex h-6 w-6 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-red-500/15 hover:text-red-400"
                      title="Supprimer"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </>
                )}
              </div>
            )}
          </div>
        )}

        {/* Reply indicator */}
        {message.reply_to && (
          <div className="mb-1 flex items-center gap-1.5 rounded-lg border-l-2 border-primary/30 bg-primary/5 px-2.5 py-1 text-[11px] text-muted-foreground/60">
            <Reply className="h-3 w-3 shrink-0 text-primary/50" />
            <span className="truncate">Réponse à un message</span>
          </div>
        )}

        {/* Message content based on type */}
        {isEditing ? (
          <div className="mt-1 space-y-2">
            <input
              className="w-full rounded-xl border border-primary/30 bg-background/80 px-3 py-2 text-sm text-foreground outline-none transition-colors focus:border-primary focus:ring-1 focus:ring-primary/20"
              value={editContent}
              onChange={(e) => setEditContent(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") handleSaveEdit();
                if (e.key === "Escape") handleCancelEdit();
              }}
              autoFocus
            />
            <div className="flex gap-2">
              <button
                onClick={handleSaveEdit}
                className="flex items-center gap-1.5 rounded-lg bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground transition-opacity hover:opacity-90"
              >
                <Check className="h-3 w-3" />
                Enregistrer
              </button>
              <button
                onClick={handleCancelEdit}
                className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-xs text-muted-foreground transition-colors hover:text-foreground"
              >
                <X className="h-3 w-3" />
                Annuler
              </button>
            </div>
          </div>
        ) : isSticker ? (
          /* Sticker message */
          <div className="py-1">
            <span className="text-5xl leading-none">{message.content}</span>
          </div>
        ) : isGif ? (
          /* GIF message */
          <div className="py-1">
            <span className="text-5xl leading-none">{message.content}</span>
          </div>
        ) : isVoice ? (
          /* Voice message with waveform animation */
          <div className={`inline-flex items-center gap-3 rounded-2xl px-4 py-2.5 ${
            isOwn
              ? "bg-gradient-to-r from-primary/15 to-primary/5 text-foreground"
              : "bg-card/80 text-foreground border border-border/50"
          }`}>
            <button
              onClick={toggleAudioPlayback}
              className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary to-accent text-primary-foreground shadow-md transition-all hover:scale-105 active:scale-95"
            >
              {isPlaying ? (
                <Pause className="h-4 w-4" />
              ) : (
                <Play className="h-4 w-4 ml-0.5" />
              )}
            </button>
            <div className="flex items-center gap-2">
              <Volume2 className={`h-3.5 w-3.5 ${isPlaying ? "text-primary" : "text-muted-foreground"}`} />
              {/* Animated waveform */}
              <div className="flex items-end gap-[1.5px] h-6">
                {Array.from({ length: 24 }).map((_, i) => {
                  const barHeight = 4 + Math.sin(i * 0.6) * 10 + Math.cos(i * 0.3) * 6 + Math.random() * 6;
                  return (
                    <div
                      key={i}
                      className="w-[3px] rounded-full transition-all"
                      style={{
                        height: `${Math.max(3, barHeight)}px`,
                        backgroundColor: isPlaying ? "var(--primary)" : "var(--muted-foreground)",
                        opacity: isPlaying ? 0.6 + Math.random() * 0.4 : 0.4,
                        animation: isPlaying ? `audio-wave ${0.4 + Math.random() * 0.6}s ease-in-out infinite ${i * 0.04}s` : "none",
                      }}
                    />
                  );
                })}
              </div>
            </div>
            <span className="text-[11px] font-mono tabular-nums text-muted-foreground">
              {message.voice_duration ? formatVoiceDuration(message.voice_duration) : "0:00"}
            </span>
            <audio
              ref={audioRef}
              src={message.voice_url || ""}
              onEnded={() => setIsPlaying(false)}
              onTimeUpdate={() => {}}
              className="hidden"
            />
          </div>
        ) : isImage ? (
          /* Image message */
          <div className="mt-1 max-w-xs">
            <img
              src={message.attachment_url || ""}
              alt="Image partagée"
              className="rounded-xl object-cover max-h-64 border border-border/30"
              loading="lazy"
            />
            {message.content && (
              <p className="mt-1 text-sm leading-6 text-foreground/90">
                {renderContent(message.content)}
              </p>
            )}
          </div>
        ) : (
          /* Regular text message */
          <p className={`text-sm leading-6 ${isOwn ? "text-foreground/95" : "text-foreground/90"}`}>
            {renderContent(message.content)}
          </p>
        )}

        {/* Attachment (non-image) */}
        {message.attachment_url && !isImage && !isVoice && (
          <a
            href={message.attachment_url}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-1.5 inline-flex items-center gap-2 rounded-xl border border-border/50 bg-card/40 px-3.5 py-2 text-xs text-primary transition-all hover:bg-card/60 hover:border-primary/30"
          >
            📎 <span className="font-medium">Pièce jointe</span>
          </a>
        )}

        {/* Reactions */}
        {groupedReactions.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-1.5">
            {groupedReactions.map(([emoji, data]) => (
              <button
                key={emoji}
                onClick={() => handleReaction(emoji)}
                className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-xs transition-all hover:scale-105 ${
                  data.users.includes(message.author_id)
                    ? "border-primary/30 bg-primary/10 text-primary"
                    : "border-border/50 bg-card/40 text-muted-foreground hover:border-primary/20"
                }`}
                title={data.users.join(", ")}
              >
                <span>{emoji}</span>
                <span className="font-medium">{data.count}</span>
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}