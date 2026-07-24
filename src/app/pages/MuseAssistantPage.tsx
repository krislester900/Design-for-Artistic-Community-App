import { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Send, Plus, Flower2, Swords } from "lucide-react";
import { useMuseTheme, MUSE_THEMES, MuseTheme } from "../components/MuseTheme";
import { MuseTopicCards, SUGGESTED_TOPICS } from "../components/MuseTopicCards";
import { CarouselStack } from "../components/CarouselStack";

const PARCHMENT_FONT =
  "'Cinzel', 'Times New Roman', 'Georgia', 'Palatino Linotype', serif";

const MUSE_REPLIES: Record<string, string> = {
  art: "Les arts visuels sont un miroir où chaque teinte raconte une époque. Commence par une seule ligne, elle suffira à ouvrir tout un univers.",
  manga: "Un bon manga commence par une respiration : la case du silence avant l’action, le détail minuscule qui révèle l’émotion.",
  music: "La musique est une onde qui traverse le corps. Si tu cherches un titre, pense d’abord à l’endroit où tu veux que l’auditeur se sente.",
  film: "Un film tient souvent dans une seule image forte. Pose-la d’abord, puis le reste viendra comme une évidence.",
  writing: "Écrire, c’est d’abord écouter le silence entre les mots. Ce qui n’est pas dit porte souvent plus que ce qui l’est.",
  animation: "L’animation donne une âme au mouvement. Trouve un seul geste lent, et il deviendra ton signal de vie.",
};

export default function MuseAssistantPage() {
  const { theme, cycleTheme } = useMuseTheme();
  const [messages, setMessages] = useState<{ id: string; role: "user" | "muse"; text: string }[]>([]);
  const [input, setInput] = useState("");
  const [showTopics, setShowTopics] = useState(true);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages]);

  const handleSend = () => {
    const text = input.trim();
    if (!text) return;
    const userMessage = { id: crypto.randomUUID(), role: "user" as const, text };
    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setShowTopics(false);

    const lower = text.toLowerCase();
    const matched = SUGGESTED_TOPICS.find((topic) => lower.includes(topic.title.toLowerCase()));
    const reply = matched
      ? MUSE_REPLIES[matched.id] ?? "Laisse-toi inspirer par ce sujet, et construis ta réponse pas à pas."
      : "Je ressens ton intention. Poursuis dans cette direction, je t’accompagne.";

    setTimeout(() => {
      setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "muse", text: reply }]);
    }, 300);
  };

  const handleTopicSelect = (topic: (typeof SUGGESTED_TOPICS)[number]) => {
    setShowTopics(false);
    const reply = MUSE_REPLIES[topic.id] ?? "Je t’écoute sur ce sujet.";
    setMessages((prev) => [
      ...prev,
      { id: crypto.randomUUID(), role: "user", text: `Parle-moi de : ${topic.title}` },
      { id: crypto.randomUUID(), role: "muse", text: reply },
    ]);
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
        <button
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Ajouter"
        >
          <Plus className="h-5 w-5" style={{ color: theme.accent }} />
        </button>
        <button
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border bg-white/5 transition hover:bg-white/10"
          style={{ borderColor: theme.border }}
          title="Dessiner en fleur de lotus"
        >
          <Flower2 className="h-5 w-5" style={{ color: theme.accent }} />
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
            className="ml-2 flex h-9 w-9 items-center justify-center rounded-full bg-white text-black transition hover:scale-105 active:scale-95"
          >
            <Send className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
