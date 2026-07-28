import { useState, useRef, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Send, Plus, Flower2, Swords, Loader2, ImageIcon, X, Lightbulb, Palette, MessageCircle, Eye, Wand2, FileText, FileSpreadsheet, FileVideo, FileWord } from "lucide-react";
import { useMuseTheme, MUSE_THEMES, MuseTheme } from "../components/MuseTheme";
import { MuseTopicCards, SUGGESTED_TOPICS } from "../components/MuseTopicCards";
import { CarouselStack } from "../components/CarouselStack";

const PARCHMENT_FONT =
  "'Cinzel', 'Times New Roman', 'Georgia', 'Palatino Linotype', serif";

export default function MuseAssistantPage() {
  const { theme, cycleTheme } = useMuseTheme();
  const [messages, setMessages] = useState<{ id: string; role: "user" | "muse"; text: string }[]>([]);
  const [input, setInput] = useState("");
  const [showTopics, setShowTopics] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [creativeTool, setCreativeTool] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages]);

  const callMuseApi = useCallback(async (text: string, imageUrl?: string) => {
    const history = messages
      .filter((m) => m.role === "user" || m.role === "muse")
      .map((m) => ({ role: m.role, content: m.text }));

    const res = await fetch("/api/muse/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        message: text,
        imageUrl,
        history,
        contentType: "general",
      }),
    });

    if (!res.ok) throw new Error("API error");
    const data = await res.json();
    return data.reply as string;
  }, [messages]);

  const handleSend = async () => {
    const text = input.trim();
    if (!text && !selectedImage) return;
    if (isLoading) return;

    const userMessage = { id: crypto.randomUUID(), role: "user" as const, text: text || "📷 Image jointe" };
    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setShowTopics(false);
    setIsLoading(true);

    try {
      const reply = await callMuseApi(text || "Décris cette image.", selectedImage || undefined);
      setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: reply }]);
    } catch {
      setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: "Hmm, Muse est en pause créative… Réessaie dans un instant. 🌙" }]);
    } finally {
      setIsLoading(false);
      setSelectedImage(null);
    }
  };

  const handleCreativeTool = async (tool: string) => {
    if (tool === "generate") {
      setCreativeTool(tool);
      setShowTopics(false);
      setIsLoading(true);
      try {
        const res = await fetch("/api/muse/generate", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ prompt: input.trim() || "une scène artistique abstraite", style: "digital art" }),
        });
        const data = await res.json();
        setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: data.imageUrl || "Pas de résultat. Réessaie. 🎨" }]);
      } catch {
        setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: "La génération a échoué. Réessaie. 🎨" }]);
      } finally {
        setIsLoading(false);
        setCreativeTool(null);
      }
      return;
    }

    if (tool.startsWith("file:")) {
      const fileType = tool.replace("file:", "");
      setCreativeTool(tool);
      setShowTopics(false);
      setIsLoading(true);
      try {
        const content = input.trim() || "Contenu généré par Muse";
        const title = "Muse Document";
        const res = await fetch(`/api/muse/generate/${fileType}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ content, title }),
        });
        if (!res.ok) throw new Error("Generation failed");
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `${title}.${fileType === "pdf" ? "pdf" : fileType === "word" ? "docx" : fileType === "excel" ? "xlsx" : "mp4"}`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: `Fichier ${fileType.toUpperCase()} téléchargé ! 📄` }]);
      } catch {
        setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: "La génération a échoué. Réessaie. 🌙" }]);
      } finally {
        setIsLoading(false);
        setCreativeTool(null);
      }
      return;
    }

    setCreativeTool(tool);
    setShowTopics(false);
    setIsLoading(true);

    try {
      const res = await fetch("/api/muse/creative", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tool, prompt: input.trim() || undefined, imageUrl: selectedImage || undefined }),
      });
      const data = await res.json();
      setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: data.result }]);
    } catch {
      setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: "Muse est en pause créative… Réessaie. 🌙" }]);
    } finally {
      setIsLoading(false);
      setCreativeTool(null);
    }
  };

  const handleTopicSelect = async (topic: (typeof SUGGESTED_TOPICS)[number]) => {

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      setSelectedImage(reader.result as string);
    };
    reader.readAsDataURL(file);
  };

  const clearImage = () => {
    setSelectedImage(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  };

  return (
    <div
      className="flex h-screen w-full flex-col overflow-hidden text-white"
      style={{
        background: theme.background,
        color: theme.text,
        fontFamily: "'Inter', sans-serif",
      }}
    >
      {/* Header */}
      <div
        className="flex items-center justify-between border-b px-4 py-3 backdrop-blur"
        style={{ borderColor: theme.border }}
      >
        <div className="flex items-center gap-2">
          <div className="h-2 w-2 rounded-full bg-white shadow-sm" />
          <span className="text-sm font-medium tracking-wide" style={{ color: theme.muted }}>
            Arteïa Muse
          </span>
          {isLoading && (
            <Loader2 className="ml-2 h-3 w-3 animate-spin" style={{ color: theme.accent }} />
          )}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={cycleTheme}
            className="flex h-9 w-9 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
            style={{ borderColor: theme.border }}
            title="Changer le thème"
          >
            <Swords className="h-5 w-5" style={{ color: theme.accent }} />
          </button>
        </div>
      </div>

      {/* Messages */}
      <div
        ref={scrollRef}
        className="flex-1 overflow-y-auto px-4 py-4"
        style={{
          background: `linear-gradient(to bottom, ${theme.background}, ${theme.glow})`,
        }}
      >
        <AnimatePresence>
          {messages.map((message) => (
            <motion.div
              key={message.id}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              className="mb-3"
            >
              {message.role === "user" ? (
                <div className="flex justify-end">
                  <div
                    className="max-w-[80%] rounded-3xl border px-4 py-3 text-right text-sm"
                    style={{
                      background: theme.surface,
                      borderColor: theme.border,
                      color: theme.text,
                    }}
                  >
                    {message.text}
                  </div>
                </div>
              ) : (
                <div
                  className="mx-auto max-w-2xl rounded-3xl border px-5 py-5 text-left shadow-xl backdrop-blur"
                  style={{
                    background: "rgba(255,255,255,0.08)",
                    borderColor: theme.border,
                    boxShadow: `0 20px 60px ${theme.glow}`,
                  }}
                >
                  <p className="text-xs font-semibold uppercase tracking-widest" style={{ color: theme.muted }}>
                    Muse
                  </p>
                  <p
                    className="mt-2 text-base leading-relaxed"
                    style={{
                      fontFamily: PARCHMENT_FONT,
                      color: theme.text,
                    }}
                  >
                    {message.text}
                  </p>
                </div>
              )}
            </motion.div>
          ))}
        </AnimatePresence>

        {showTopics && (
          <div className="mt-4">
            <p className="mb-3 text-center text-xs uppercase tracking-widest" style={{ color: theme.muted }}>
              Choisis un sujet
            </p>
            <CarouselStack />
          </div>
        )}
      </div>

      {/* Bottom bar */}
      <div
        className="flex items-end gap-2 border-t px-4 py-3 backdrop-blur"
        style={{ borderColor: theme.border, background: theme.background }}
      >
        {/* Image upload */}
        <button
          onClick={() => fileInputRef.current?.click()}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Joindre une image"
        >
          <ImageIcon className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          className="hidden"
          onChange={handleImageSelect}
        />

        {selectedImage && (
          <div className="relative h-11 w-11 shrink-0">
            <img src={selectedImage} alt="aperçu" className="h-full w-full rounded-full object-cover" />
            <button
              onClick={clearImage}
              className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-black/70 text-white"
            >
              <X className="h-3 w-3" />
            </button>
          </div>
        )}

        {/* Creative tools */}
        <button
          onClick={() => handleCreativeTool("generate")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Générer une image"
        >
          <Wand2 className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          onClick={() => handleCreativeTool("file:pdf")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Générer un PDF"
        >
          <FileText className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          onClick={() => handleCreativeTool("file:word")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Générer un Word"
        >
          <FileWord className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          onClick={() => handleCreativeTool("file:excel")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Générer un Excel"
        >
          <FileSpreadsheet className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          onClick={() => handleCreativeTool("file:video")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Générer une vidéo"
        >
          <FileVideo className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          onClick={() => handleCreativeTool("ideas")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Générer des idées"
        >
          <Lightbulb className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          onClick={() => handleCreativeTool("style")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Analyser le style"
        >
          <Palette className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          onClick={() => handleCreativeTool("critique")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Critique d'art"
        >
          <MessageCircle className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          onClick={() => handleCreativeTool("describe")}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Décrire l'image"
        >
          <Eye className="h-5 w-5" style={{ color: theme.accent }} />
        </button>

        <div className="flex flex-1 items-center rounded-full border bg-white/5 px-4" style={{ borderColor: theme.border }}>
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleSend()}
            placeholder="Écris à Muse…"
            className="flex-1 bg-transparent py-3 text-sm outline-none"
            style={{ color: theme.text }}
          />
          <button
            onClick={handleSend}
            disabled={isLoading}
            className="ml-2 flex h-9 w-9 items-center justify-center rounded-full bg-white text-black transition hover:scale-105 active:scale-95 disabled:opacity-50"
          >
            {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
          </button>
        </div>
      </div>
    </div>
  );
}