import { Send, Paperclip, X, Mic, Smile, Image, Film, Upload } from "lucide-react";
import { useState, useRef, useCallback } from "react";
import { EmojiPicker } from "./EmojiPicker";
import { StickerPicker } from "./StickerPicker";
import { GifPicker } from "./GifPicker";
import { VoiceRecorder } from "./VoiceRecorder";

type ChatInputProps = {
  onSend: (content: string, attachmentUrl?: string) => void;
  onSendVoice?: (audioBlob: Blob, duration: number) => void;
  onSendSticker?: (stickerId: string, stickerUrl: string) => void;
  onSendGif?: (gifUrl: string) => void;
  onFileUpload?: (file: File) => void;
  replyTo: { id: string; content: string } | null;
  onCancelReply: () => void;
  disabled?: boolean;
  typingIndicator?: React.ReactNode;
};

export function ChatInput({
  onSend,
  onSendVoice,
  onSendSticker,
  onSendGif,
  onFileUpload,
  replyTo,
  onCancelReply,
  disabled,
  typingIndicator,
}: ChatInputProps) {
  const [content, setContent] = useState("");
  const [attachmentUrl, setAttachmentUrl] = useState("");
  const [showEmoji, setShowEmoji] = useState(false);
  const [showStickers, setShowStickers] = useState(false);
  const [showGifs, setShowGifs] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);
  const [uploadPreview, setUploadPreview] = useState<string | null>(null);
  const [uploadFileName, setUploadFileName] = useState<string>("");

  const inputRef = useRef<HTMLInputElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  function handleSubmit() {
    if (!content.trim() && !attachmentUrl) return;
    onSend(content.trim(), attachmentUrl || undefined);
    setContent("");
    setAttachmentUrl("");
    setUploadPreview(null);
    setUploadFileName("");
    setShowEmoji(false);
    inputRef.current?.focus();
  }

  function handleEmojiSelect(emoji: string) {
    setContent((prev) => prev + emoji);
    inputRef.current?.focus();
  }

  function handleStickerSelect(stickerId: string, stickerUrl: string) {
    onSendSticker?.(stickerId, stickerUrl);
    setShowStickers(false);
  }

  function handleGifSelect(gifUrl: string) {
    onSendGif?.(gifUrl);
    setShowGifs(false);
  }

  function handleFileSelect(file: File) {
    if (onFileUpload) {
      onFileUpload(file);
      setUploadFileName(file.name);
      // Create preview for images
      if (file.type.startsWith("image/")) {
        const reader = new FileReader();
        reader.onload = (e) => setUploadPreview(e.target?.result as string);
        reader.readAsDataURL(file);
      } else {
        setUploadPreview(null);
      }
    } else {
      // Fallback: use URL prompt
      const url = prompt("Colle l'URL de la pièce jointe :");
      if (url) setAttachmentUrl(url);
    }
  }

  function handleDragOver(e: React.DragEvent) {
    e.preventDefault();
    setIsDragOver(true);
  }

  function handleDragLeave() {
    setIsDragOver(false);
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    setIsDragOver(false);
    const file = e.dataTransfer.files[0];
    if (file) handleFileSelect(file);
  }

  function handleSendVoice(audioBlob: Blob, duration: number) {
    onSendVoice?.(audioBlob, duration);
    setIsRecording(false);
  }

  function closeAllPickers() {
    setShowEmoji(false);
    setShowStickers(false);
    setShowGifs(false);
  }

  function toggleEmoji() {
    const newState = !showEmoji;
    closeAllPickers();
    setShowEmoji(newState);
  }

  function toggleStickers() {
    const newState = !showStickers;
    closeAllPickers();
    setShowStickers(newState);
  }

  function toggleGifs() {
    const newState = !showGifs;
    closeAllPickers();
    setShowGifs(newState);
  }

  // Voice recording mode
  if (isRecording) {
    return (
      <div className="border-t border-border/50 bg-gradient-to-t from-card/50 to-card/30 px-6 py-4 backdrop-blur-xl">
        <VoiceRecorder
          onSendVoice={handleSendVoice}
          onCancel={() => setIsRecording(false)}
        />
      </div>
    );
  }

  return (
    <div
      className={`border-t border-border/50 bg-gradient-to-t from-card/50 to-card/30 px-6 py-4 backdrop-blur-xl transition-colors animated-gradient ${
               isDragOver ? "ring-2 ring-primary/40 bg-primary/5" : ""
      }`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {/* Reply indicator */}
      {replyTo && (
        <div className="mb-3 flex items-center gap-2 rounded-xl border border-primary/20 bg-primary/5 px-3 py-2 text-xs text-muted-foreground backdrop-blur-sm">
          <span className="font-medium text-primary">↪ Réponse à :</span>
          <span className="truncate flex-1">{replyTo.content}</span>
          <button
            onClick={onCancelReply}
            className="flex h-5 w-5 items-center justify-center rounded-md text-muted-foreground hover:bg-card/60 hover:text-foreground transition-colors"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      )}

      {/* Upload preview */}
      {(attachmentUrl || uploadPreview) && (
        <div className="mb-3 flex items-center gap-2 rounded-xl border border-primary/20 bg-primary/5 px-3 py-2 text-xs backdrop-blur-sm">
          {uploadPreview ? (
            <img src={uploadPreview} alt="Aperçu" className="h-10 w-10 rounded-lg object-cover" />
          ) : (
            <span className="text-lg">📎</span>
          )}
          <span className="truncate text-muted-foreground flex-1">{uploadFileName || attachmentUrl}</span>
          <button
            onClick={() => { setAttachmentUrl(""); setUploadPreview(null); setUploadFileName(""); }}
            className="flex h-5 w-5 items-center justify-center rounded-md text-muted-foreground hover:bg-card/60 hover:text-foreground transition-colors"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      )}

      {/* Drag & drop overlay */}
      {isDragOver && (
        <div className="mb-3 flex items-center justify-center rounded-xl border-2 border-dashed border-primary/40 bg-primary/5 py-4 text-sm text-primary/70">
          <Upload className="mr-2 h-4 w-4" />
          Dépose ton fichier ici...
        </div>
      )}

      {/* Pickers */}
      <div className="relative">
        {showEmoji && (
          <EmojiPicker onSelect={handleEmojiSelect} onClose={() => setShowEmoji(false)} />
        )}
        {showStickers && (
          <StickerPicker onSelect={handleStickerSelect} onClose={() => setShowStickers(false)} />
        )}
        {showGifs && (
          <GifPicker onSelect={handleGifSelect} onClose={() => setShowGifs(false)} />
        )}
      </div>

      {/* Typing indicator */}
      {typingIndicator}

      {/* Input bar */}
      <div className="flex items-end gap-2">
        {/* Action buttons */}
        <div className="flex items-center gap-0.5 pb-1">
          {/* File upload */}
          <button
            onClick={() => fileInputRef.current?.click()}
            className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground transition-colors hover:bg-primary/10 hover:text-primary"
            title="Joindre un fichier"
            disabled={disabled}
          >
            <Paperclip className="h-4 w-4" />
          </button>
          <input
            ref={fileInputRef}
            type="file"
            className="hidden"
            accept="image/*,video/*,.pdf,.doc,.docx,.txt,.zip"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) handleFileSelect(file);
              e.target.value = "";
            }}
          />

          {/* Image upload */}
          <button
            onClick={() => {
              const input = document.createElement("input");
              input.type = "file";
              input.accept = "image/*";
              input.onchange = (e) => {
                const file = (e.target as HTMLInputElement).files?.[0];
                if (file) handleFileSelect(file);
              };
              input.click();
            }}
            className="flex h-9 w-9 items-center justify-center rounded-xl text-muted-foreground transition-colors hover:bg-primary/10 hover:text-primary"
            title="Envoyer une image"
            disabled={disabled}
          >
            <Image className="h-4 w-4" />
          </button>

          {/* Emoji */}
          <button
            onClick={toggleEmoji}
            className={`flex h-9 w-9 items-center justify-center rounded-xl transition-colors ${
              showEmoji
                ? "bg-primary/15 text-primary"
                : "text-muted-foreground hover:bg-primary/10 hover:text-primary"
            }`}
            title="Émojis"
            disabled={disabled}
          >
            <Smile className="h-4 w-4" />
          </button>

          {/* Stickers */}
          <button
            onClick={toggleStickers}
            className={`flex h-9 w-9 items-center justify-center rounded-xl text-lg transition-colors ${
              showStickers
                ? "bg-primary/15"
                : "hover:bg-primary/10"
            }`}
            title="Stickers"
            disabled={disabled}
          >
            🎭
          </button>

          {/* GIFs */}
          <button
            onClick={toggleGifs}
            className={`flex h-9 w-9 items-center justify-center rounded-xl text-xs font-bold transition-colors ${
              showGifs
                ? "bg-primary/15 text-primary"
                : "text-muted-foreground hover:bg-primary/10 hover:text-primary"
            }`}
            title="GIFs"
            disabled={disabled}
          >
            <Film className="h-4 w-4" />
          </button>
        </div>

        {/* Text input */}
        <div className="relative flex-1">
          <input
            ref={inputRef}
            className="w-full rounded-2xl border border-border/50 bg-card/60 px-4 py-3 pr-4 text-sm text-foreground outline-none transition-all placeholder:text-muted-foreground/40 focus:border-primary/50 focus:ring-2 focus:ring-primary/10 backdrop-blur-sm"
            placeholder={disabled ? "Connecte-toi pour discuter..." : "Écris un message..."}
            value={content}
            onChange={(e) => setContent(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                handleSubmit();
              }
            }}
            disabled={disabled}
          />
        </div>

        {/* Voice / Send button */}
        {content.trim() || attachmentUrl ? (
          <button
            onClick={handleSubmit}
            disabled={disabled}
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-primary/80 text-primary-foreground shadow-lg shadow-primary/20 transition-all hover:shadow-xl hover:shadow-primary/30 hover:scale-105 active:scale-95 disabled:opacity-40 disabled:shadow-none disabled:hover:scale-100 send-press"
          >
            <Send className="h-4 w-4" />
          </button>
        ) : (
          <button
            onClick={() => setIsRecording(true)}
            disabled={disabled}
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-muted to-muted/80 text-muted-foreground shadow-md transition-all hover:shadow-lg hover:text-primary hover:from-primary/10 hover:to-primary/5 disabled:opacity-40 disabled:shadow-none"
            title="Message vocal"
          >
            <Mic className="h-4 w-4" />
          </button>
        )}
      </div>
    </div>
  );
}