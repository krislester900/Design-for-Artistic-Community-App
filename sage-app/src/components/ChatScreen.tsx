import { useState, useRef, useEffect } from 'react'
import { PERSONALITIES, sendMessage, type Personality } from '../services/aiService'

interface Message {
  role: 'user' | 'assistant'
  content: string
}

function PersonalityCard({ p, selected, onClick }: { p: Personality; selected: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`personality-btn flex items-center gap-3 ${
        selected 
          ? 'border-sage-500 bg-sage-500/10' 
          : 'bg-white/5'
      }`}
    >
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center text-2xl bg-gradient-to-br ${p.gradient} shadow-lg`}>
        {p.icon}
      </div>
      <div className="flex-1 min-w-0">
        <h3 className="font-semibold text-white text-sm">{p.name}</h3>
        <p className="text-xs text-white/60 truncate">{p.description}</p>
      </div>
      {selected && (
        <div className="w-3 h-3 rounded-full bg-sage-400 animate-pulse-glow" />
      )}
    </button>
  )
}

function ChatMessage({ message }: { message: Message }) {
  return (
    <div className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'} animate-fadeIn`}>
      <div className={`chat-message ${message.role === 'user' ? 'message-user' : 'message-ai'}`}>
        {message.content.split('\n').map((line, i) => (
          <span key={i}>
            {line}
            {i < message.content.split('\n').length - 1 && <br />}
          </span>
        ))}
      </div>
    </div>
  )
}

function TypingIndicator() {
  return (
    <div className="flex justify-start animate-fadeIn">
      <div className="chat-message message-ai flex items-center gap-1.5 py-4">
        <div className="typing-dot" />
        <div className="typing-dot" />
        <div className="typing-dot" />
      </div>
    </div>
  )
}

function WelcomeScreen({ onSelectPersonality }: { onSelectPersonality: (p: Personality) => void }) {
  return (
    <div className="flex-1 flex flex-col items-center justify-center p-6 overflow-y-auto">
      <div className="text-center mb-8">
        <div className="w-20 h-20 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-sage-400 to-purple-500 flex items-center justify-center text-4xl animate-float shadow-2xl">
          🧘
        </div>
        <h1 className="text-3xl font-bold text-white mb-2">Bienvenue sur <span className="bg-gradient-to-r from-sage-300 to-purple-400 bg-clip-text text-transparent">Sage</span></h1>
        <p className="text-white/60 text-sm max-w-xs mx-auto">
          Ton assistant IA multi-personnalités. Choisis qui tu veux dans ton équipe !
        </p>
      </div>

      <div className="w-full max-w-md space-y-3">
        <p className="text-xs text-white/40 text-center uppercase tracking-wider font-medium mb-2">
          Choisis ta personnalité
        </p>
        {PERSONALITIES.map(p => (
          <PersonalityCard
            key={p.id}
            p={p}
            selected={false}
            onClick={() => onSelectPersonality(p)}
          />
        ))}
      </div>

      <div className="mt-8 text-center">
        <div className="flex items-center gap-2 text-white/30 text-xs">
          <span className="w-1 h-1 rounded-full bg-green-400 animate-pulse" />
          100% Gratuit
          <span className="w-1 h-1 rounded-full bg-sage-400" />
          IA Puissante
        </div>
      </div>
    </div>
  )
}

export default function ChatScreen() {
  const [selectedPersonality, setSelectedPersonality] = useState<Personality | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [showPersonalities, setShowPersonalities] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLTextAreaElement>(null)

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isLoading])

  useEffect(() => {
    if (selectedPersonality && messages.length === 0) {
      const greetings: Record<string, string> = {
        psy: "Bonjour 👋 Je suis ton psychologue personnel. Assieds-toi, prends ton temps. Raconte-moi ce qui te traverse l'esprit en ce moment. Comment te sens-tu aujourd'hui ?",
        chef: "Salut ! 👨‍🍳 Bienvenue dans ma cuisine ! Prêt(e) à préparer quelque chose de délicieux ? Dis-moi ce que tu as envie de cuisiner ou quels ingrédients tu as !",
        prof: "Bonjour et bienvenue ! 📚 Je suis là pour t'aider à apprendre et comprendre. Qu'est-ce qui te pose problème ? Une matière ? Un concept ? On va le décortiquer ensemble !",
        langues: "Hello ! ¡Hola ! Ciao ! 👋 Quelle langue veux-tu apprendre ou pratiquer aujourd'hui ? Je peux t'aider avec l'anglais, l'espagnol, l'italien et plus encore !",
        ami: "Hééé ! Trop content de te voir ! 😄 Alors, raconte, comment ça va ? Les dernières nouvelles ? Dis-moi tout, je suis tout ouïe !",
        savant: "Salutations, curieux esprit ! 🔬 Prêt à explorer les mystères de l'univers ? De la mécanique quantique à la biologie synthétique, pose-moi toutes tes questions !"
      }
      setMessages([{ role: 'assistant', content: greetings[selectedPersonality.id] || `Bonjour ! Je suis ${selectedPersonality.name}, comment puis-je t'aider ?` }])
    }
  }, [selectedPersonality])

  const handleSend = async () => {
    if (!input.trim() || isLoading || !selectedPersonality) return
    
    const userMessage = input.trim()
    setInput('')
    setError(null)
    setMessages(prev => [...prev, { role: 'user', content: userMessage }])
    setIsLoading(true)

    try {
      const response = await sendMessage(
        selectedPersonality,
        userMessage,
        messages.slice(-10).map(m => ({ role: m.role, content: m.content }))
      )
      setMessages(prev => [...prev, { role: 'assistant', content: response }])
    } catch (e) {
      setError('Désolé, une erreur est survenue. Réessaie !')
      setMessages(prev => [...prev, { role: 'assistant', content: 'Désolé, je n\'ai pas pu répondre. Peux-tu reformuler ? 😊' }])
    } finally {
      setIsLoading(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  const selectPersonality = (p: Personality) => {
    setSelectedPersonality(p)
    setMessages([])
    setShowPersonalities(false)
    setError(null)
  }

  if (!selectedPersonality) {
    return (
      <div className="h-full flex flex-col bg-gradient-to-br from-indigo-950 via-purple-950 to-slate-950">
        <WelcomeScreen onSelectPersonality={selectPersonality} />
      </div>
    )
  }

  return (
    <div className="h-full flex flex-col bg-gradient-to-br from-indigo-950 via-purple-950 to-slate-950">
      {/* Header */}
      <div className="glass-strong px-4 py-3 flex items-center gap-3 sticky top-0 z-10">
        <button
          onClick={() => setShowPersonalities(!showPersonalities)}
          className="w-9 h-9 rounded-xl bg-white/10 flex items-center justify-center text-lg hover:bg-white/20 transition-colors"
        >
          {showPersonalities ? '✕' : '☰'}
        </button>
        
        <div className={`w-9 h-9 rounded-lg flex items-center justify-center text-lg bg-gradient-to-br ${selectedPersonality.gradient}`}>
          {selectedPersonality.icon}
        </div>
        
        <div className="flex-1">
          <h2 className="text-white font-semibold text-sm">{selectedPersonality.name}</h2>
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
            <span className="text-white/50 text-xs">En ligne</span>
          </div>
        </div>

        <button
          onClick={() => { setSelectedPersonality(null); setMessages([]); setError(null) }}
          className="text-white/40 text-xs hover:text-white/80 transition-colors px-2"
        >
          Changer
        </button>
      </div>

      {/* Personnalités panel */}
      {showPersonalities && (
        <div className="glass-strong mx-3 mt-2 rounded-2xl p-3 space-y-2 max-h-[40vh] overflow-y-auto scrollbar-thin z-20">
          {PERSONALITIES.filter(p => p.id !== selectedPersonality.id).map(p => (
            <PersonalityCard
              key={p.id}
              p={p}
              selected={false}
              onClick={() => selectPersonality(p)}
            />
          ))}
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3 scrollbar-thin">
        {messages.map((msg, i) => (
          <ChatMessage key={i} message={msg} />
        ))}
        {isLoading && <TypingIndicator />}
        {error && (
          <div className="text-center text-red-400 text-xs animate-fadeIn bg-red-500/10 rounded-xl px-4 py-2 mx-auto max-w-xs">
            {error}
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="glass-strong px-4 py-3 pb-6">
        <div className="flex items-end gap-2 max-w-2xl mx-auto">
          <div className="flex-1 relative">
            <textarea
              ref={inputRef}
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder={`Parle à ${selectedPersonality.name}...`}
              rows={1}
              className="w-full bg-white/10 rounded-2xl px-4 py-3 pr-12 text-white placeholder-white/40 
                         resize-none outline-none border border-white/10 focus:border-sage-500/50 
                         transition-colors text-sm max-h-32 scrollbar-thin"
              style={{ minHeight: '48px' }}
            />
          </div>
          <button
            onClick={handleSend}
            disabled={!input.trim() || isLoading}
            className={`w-12 h-12 rounded-xl flex items-center justify-center text-xl transition-all ${
              input.trim() && !isLoading
                ? 'bg-gradient-to-br from-sage-500 to-purple-600 text-white shadow-lg hover:shadow-sage-500/30 hover:scale-105 active:scale-95'
                : 'bg-white/10 text-white/30'
            }`}
          >
            {isLoading ? '⏳' : '➤'}
          </button>
        </div>
        <p className="text-center text-white/20 text-xs mt-2">
          Sage utilise l'IA via Hugging Face · Gratuit et privé
        </p>
      </div>
    </div>
  )
}