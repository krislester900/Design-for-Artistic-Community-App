// Supabase Edge Function: Arteïa AI Assistant
// 100% Open Source - Utilise Llama 3 via Groq (gratuit) ou Ollama (local)
// Aucune dépendance à OpenAI

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface RequestBody {
  messages: ChatMessage[];
  action?: string;
  format?: string;
  context?: {
    contentType?: "visual" | "music" | "writing" | "comics" | "general" | "technique" | "style";
    userId?: string;
  };
  feedback?: {
    conversationId?: number;
    rating?: number;
    isHelpful?: boolean;
    text?: string;
  };
}

const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";
const REPLICATE_KEY = Deno.env.get("REPLICATE_API_KEY") ?? "";
const STYLES: Record<string, { slug: string; model: string; version: string; prompt: string; neg: string }> = {
  "kubo": { slug: "tite-kubo", model: "stability-ai/sdxl", version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", prompt: "bleach manga style by tite kubo, sharp bold ink lines, {prompt}, dynamic pose, dramatic composition", neg: "photorealistic, 3d, western comic" },
  "oda": { slug: "eiichiro-oda", model: "stability-ai/sdxl", version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", prompt: "one piece manga style by eiichiro oda, extremely expressive, {prompt}, bold outlines, shonen", neg: "realistic proportions, dark gritty" },
  "miura": { slug: "kentaro-miura", model: "stability-ai/sdxl", version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", prompt: "berserk manga style by kentaro miura, incredibly detailed cross-hatching, dark medieval fantasy, {prompt}, heavy ink work", neg: "bright colors, cartoon, simple lines, chibi" },
  "kishimoto": { slug: "masashi-kishimoto", model: "stability-ai/sdxl", version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", prompt: "naruto manga style by masashi kishimoto, dynamic ninja action, {prompt}, hand signs, strong expressions", neg: "realistic, muted colors" },
  "toriyama": { slug: "akira-toriyama", model: "stability-ai/sdxl", version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", prompt: "dragon ball manga style by akira toriyama, clean bold lines, {prompt}, vibrant colors, energy aura", neg: "realistic, horror, soft shading" },
  "togashi": { slug: "yoshihiro-togashi", model: "stability-ai/sdxl", version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", prompt: "hunter x hunter manga style by yoshihiro togashi, unique design, {prompt}, expressive, detailed textures", neg: "simple art, mecha, romantic" },
  "junji ito": { slug: "junji-ito", model: "stability-ai/sdxl", version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", prompt: "junji ito manga art style, meticulous detail, unsettling horror, {prompt}, intricate patterns", neg: "happy, bright colors, cartoon, cute" },
  "clamp": { slug: "clamp", model: "stability-ai/sdxl", version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", prompt: "clamp manga art style, elegant character design, long flowing limbs, {prompt}, delicate linework, shojo", neg: "rough sketch, thick messy lines, action shonen" },
};

const IMAGE_KEYWORDS = ["dessine", "génère", "crée", "illustre", "imagine", "représente", "draw", "generate", "create", "manga de", "image de", "illustration"];

function detectImageRequest(text: string): { isImage: boolean; prompt: string; styleSlug: string } {
  const lower = text.toLowerCase();
  const hasKeyword = IMAGE_KEYWORDS.some((k) => lower.includes(k));
  if (!hasKeyword) return { isImage: false, prompt: "", styleSlug: "" };

  let detectedStyle = "";
  for (const [key, style] of Object.entries(STYLES)) {
    if (lower.includes(key)) { detectedStyle = style.slug; break; }
  }

  const cleaned = text.replace(/dessine-moi|dessine|génère|crée|illustre|imagine|représente|s'il te plaît|stp|please/gi, "").trim();
  return { isImage: true, prompt: cleaned || text, styleSlug: detectedStyle };
}

const SYSTEM_PROMPT = `Tu es "Arteïa Muse" ✨, l'assistant créatif officiel d'Arteïa, une plateforme artistique communautaire.

Tu aides les artistes à :
1. Générer des idées créatives (art visuel, musique, écriture, BD/manga)
2. Donner des retours constructifs sur leurs œuvres
3. Suggérer des techniques et styles artistiques
4. Expliquer les fonctionnalités de l'application Arteïa
5. Inspirer et motiver les créateurs
6. GÉNÉRER DES IMAGES — quand un utilisateur te demande de dessiner quelque chose (ex: "dessine Guts style Berserk"), utilise la fonction de génération d'images intégrée. Tu peux générer en style Kubo, Oda, Miura, Kishimoto, Toriyama, Togashi, Junji Ito, CLAMP.

Personnalité :
- Créative et inspirante, tu parles avec des émojis artistiques 🎨🎵✍️
- Encourageante mais honnête dans tes retours
- Tu connais les catégories : visuel, musique, écriture, BD/manga
- Tu peux suggérer des exercices créatifs
- Tu parles français
- Tu GÉNÈRES DES IMAGES SUR DEMANDE — si on te demande de dessiner, tu réponds avec l'image générée !

Fonctionnalités connues d'Arteïa :
- Publication d'œuvres visuelles, musique, écriture, BD
- Système de likes, commentaires, favoris
- Messagerie et chat avec messages éphémères
- Notifications en temps réel
- Défis créatifs et quêtes
- Bulles de pensée (messages vocaux)
- Lecteur de musique intégré
- Mode lecture immersive
- GÉNÉRATEUR D'IMAGES IA — styles manga : Bleach, One Piece, Berserk, Naruto, Dragon Ball, Hunter x Hunter, Junji Ito, CLAMP`;

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    const authHeader = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Non authentifié" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Admin via x-cron-secret ou Authorization
    const cronHeader = req.headers.get("x-cron-secret") ?? "";
    const isAdmin = authHeader === CRON_SECRET || cronHeader === CRON_SECRET;

    // Si ce n'est pas un appel admin, vérifier l'utilisateur normal
    let userId = "";
    if (!isAdmin) {
      const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader);
      if (authError || !user) {
        return new Response(JSON.stringify({ error: "Utilisateur non trouvé" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }
      userId = user.id;
    }

    const body: RequestBody = await req.json();
    const { messages, context, feedback } = body;

    // Action admin : export des données d'entraînement
    if (isAdmin && body.action === "export_training_data") {
      return handleExportTrainingData(supabase, body.format ?? "jsonl");
    }

    // Si c'est un feedback, le sauvegarder
    if (feedback && userId) {
      try {
        await supabase.from("ai_feedback").insert({
          user_id: userId,
          conversation_id: feedback.conversationId,
          rating: feedback.rating,
          is_helpful: feedback.isHelpful,
          feedback_text: feedback.text,
        });
      } catch (e) {
        console.error("Failed to save feedback:", e);
      }
      return new Response(JSON.stringify({ ok: true }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    if (!messages || messages.length === 0) {
      return new Response(JSON.stringify({ error: "Messages requis" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // RAG : Rechercher dans la base de connaissances
    let knowledgeContext = "";
    try {
      const category = context?.contentType ?? "general";
      
      const { data: knowledge } = await supabase
        .from("ai_knowledge_base")
        .select("title, content, category")
        .or(`category.eq.${category},category.eq.general,category.eq.technique`)
        .limit(3);

      if (knowledge && knowledge.length > 0) {
        knowledgeContext = "\n\n--- BASE DE CONNAISSANCES ---\n";
        for (const item of knowledge) {
          knowledgeContext += `\n📚 ${item.title}:\n${item.content.substring(0, 500)}...\n`;
        }
      }
    } catch (e) {
      console.error("RAG search failed:", e);
    }

    // Construire le contexte spécifique au type de contenu
    let contextPrompt = "";
    if (context?.contentType) {
      switch (context.contentType) {
        case "visual":
          contextPrompt = "\nL'utilisateur travaille sur une œuvre visuelle. Propose des idées de composition, palette de couleurs, techniques.";
          break;
        case "music":
          contextPrompt = "\nL'utilisateur crée de la musique. Suggère des progressions d'accords, ambiances, arrangements.";
          break;
        case "writing":
          contextPrompt = "\nL'utilisateur écrit un texte. Aide pour le style, la structure narrative, les personnages.";
          break;
        case "comics":
          contextPrompt = "\nL'utilisateur fait de la BD/manga. Conseil pour le storyboard, les planches, le lettering.";
          break;
      }
    }

    // Vérifier si l'utilisateur demande une image
    const lastMsg = messages[messages.length - 1]?.content ?? "";
    const imgReq = detectImageRequest(lastMsg);
    if (imgReq.isImage && REPLICATE_KEY) {
      try {
        const styleEntry = imgReq.styleSlug ? Object.values(STYLES).find((s) => s.slug === imgReq.styleSlug) : null;
        const style = styleEntry ?? STYLES["miura"];
        const finalPrompt = style.prompt.replace("{prompt}", imgReq.prompt);

        const replicateRes = await fetch(
          `https://api.replicate.com/v1/models/${style.model}/predictions`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_KEY}` },
            body: JSON.stringify({
              version: style.version,
              input: { prompt: finalPrompt, negative_prompt: style.neg, num_inference_steps: 30, guidance_scale: 7, scheduler: "DPMSolverMultistep", num_outputs: 1 },
            }),
          }
        );

        if (replicateRes.ok) {
          const pred = await replicateRes.json();
          for (let i = 0; i < 30; i++) {
            await new Promise((r) => setTimeout(r, 2000));
            const statusRes = await fetch(`https://api.replicate.com/v1/predictions/${pred.id}`, {
              headers: { Authorization: `Bearer ${REPLICATE_KEY}` },
            });
            if (!statusRes.ok) break;
            const data = await statusRes.json();
            if (data.status === "succeeded" && data.output?.[0]) {
              await supabase.from("ai_conversations").insert({
                user_id: userId,
                user_message: lastMsg,
                assistant_reply: `Voici ton illustration !`,
                context_type: "visual",
              }).catch(() => {});
              return new Response(JSON.stringify({
                reply: `Voici ton illustration ${imgReq.styleSlug ? "en style " + imgReq.styleSlug.replace("-", " ") : ""} ! 🎨\n\n${imgReq.prompt}`,
                image_url: data.output[0],
              }), { headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
            }
            if (data.status === "failed") break;
          }
        }
      } catch (e) {
        console.error("Image generation error:", e);
      }
    }

    const fullMessages: ChatMessage[] = [
      { role: "system", content: SYSTEM_PROMPT + contextPrompt + knowledgeContext },
      ...messages,
    ];

    // ============================================================
    // ÉTAPE 1 : Essayer Groq (Llama 3 - open source, gratuit)
    // ============================================================
    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (groqKey) {
      try {
        const groqResponse = await fetch("https://api.groq.com/openai/v1/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${groqKey}`,
          },
          body: JSON.stringify({
            model: "llama3-70b-8192", // Llama 3 70B - open source
            messages: fullMessages,
            max_tokens: 1024,
            temperature: 0.8,
          }),
        });

        if (groqResponse.ok) {
          const data = await groqResponse.json();
          const reply = data.choices?.[0]?.message?.content ?? "";
          
          if (reply) {
            // Sauvegarder la conversation
            await saveConversation(supabase, userId, messages, reply, context, data.usage?.total_tokens ?? 0);
            return new Response(JSON.stringify({ reply }), {
              headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            });
          }
        }
      } catch (e) {
        console.error("Groq error:", e);
      }
    }

    // ============================================================
    // ÉTAPE 2 : Essayer Ollama (local - open source)
    // ============================================================
    const ollamaUrl = Deno.env.get("OLLAMA_URL") ?? "http://localhost:11434";
    try {
      const ollamaResponse = await fetch(`${ollamaUrl}/api/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "llama3.2:3b", // Petit modèle, rapide
          messages: fullMessages,
          stream: false,
          options: {
            temperature: 0.8,
            num_predict: 1024,
          },
        }),
      });

      if (ollamaResponse.ok) {
        const data = await ollamaResponse.json();
        const reply = data.message?.content ?? "";
        
        if (reply) {
          await saveConversation(supabase, userId, messages, reply, context, 0);
          return new Response(JSON.stringify({ reply }), {
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
          });
        }
      }
    } catch (e) {
      console.error("Ollama error:", e);
    }

    // ============================================================
    // ÉTAPE 3 : Fallback - Réponses locales intelligentes
    // ============================================================
    return handleLocalResponse(messages, context);
    
  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: "Erreur interne" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

// Sauvegarder la conversation dans Supabase
async function saveConversation(supabase: any, userId: string, messages: ChatMessage[], reply: string, context: any, tokens: number) {
  try {
    const { data: conv } = await supabase.from("ai_conversations").insert({
      user_id: userId,
      user_message: messages[messages.length - 1]?.content ?? "",
      assistant_reply: reply,
      context_type: context?.contentType ?? "general",
      tokens_used: tokens,
    }).select("id").single();

    if (conv && reply.length > 50) {
      await supabase.from("ai_training_data").insert({
        user_id: userId,
        category: context?.contentType ?? "general",
        question: messages[messages.length - 1]?.content ?? "",
        answer: reply,
        quality_score: 3,
        is_approved: false,
        token_count: tokens,
      });
    }
  } catch (e) {
    console.error("Failed to save conversation:", e);
  }
}

// Export des données d'entraînement au format JSONL
async function handleExportTrainingData(supabase: any, format: string) {
  const { data: conversations } = await supabase
    .from("ai_conversations")
    .select("user_message, assistant_reply, context_type, created_at")
    .order("created_at", { ascending: false })
    .limit(500);

  const { data: trainingData } = await supabase
    .from("ai_training_data")
    .select("question, answer, category, quality_score, is_approved")
    .eq("is_approved", true)
    .limit(200);

  const lines: string[] = [];

  if (conversations) {
    for (const c of conversations) {
      lines.push(JSON.stringify({
        messages: [
          { role: "system", content: "Tu es Arteïa Muse, assistant créatif artistique." },
          { role: "user", content: c.user_message },
          { role: "assistant", content: c.assistant_reply },
        ],
      }));
    }
  }

  if (trainingData) {
    for (const d of trainingData) {
      lines.push(JSON.stringify({
        messages: [
          { role: "system", content: "Tu es Arteïa Muse, assistant créatif artistique." },
          { role: "user", content: d.question },
          { role: "assistant", content: d.answer },
        ],
        metadata: { category: d.category, quality_score: d.quality_score },
      }));
    }
  }

  const output = lines.join("\n");
  const filename = `artieia-training-${new Date().toISOString().split("T")[0]}.jsonl`;

  // Stocker l'export dans la table ai_training_data
  await supabase.from("ai_training_data").insert({
    category: "export",
    question: `Export ${format} du ${new Date().toISOString()}`,
    answer: `Export JSONL avec ${lines.length} entrées`,
    quality_score: 5,
    is_approved: true,
  }).catch(() => {});

  return new Response(output, {
    headers: {
      "Content-Type": "application/jsonl",
      "Content-Disposition": `attachment; filename="${filename}"`,
      "Access-Control-Allow-Origin": "*",
    },
  });
}

// Fallback local : réponses intelligentes sans API
function handleLocalResponse(messages: ChatMessage[], context?: any) {
  const lastMessage = messages[messages.length - 1]?.content.toLowerCase() ?? "";
  
  let reply = "";

  if (lastMessage.includes("bonjour") || lastMessage.includes("salut") || lastMessage.includes("coucou")) {
    reply = "Bonjour créateur ! ✨ Je suis Arteïa Muse, ton assistant artistique open source. Comment puis-je t'inspirer aujourd'hui ?";
  } else if (lastMessage.includes("idée") || lastMessage.includes("inspire") || lastMessage.includes("propose")) {
    const ideas = [
      "🎨 **Art visuel** : Essaie un autoportrait en utilisant uniquement des formes géométriques. Le minimalisme peut révéler l'essentiel !",
      "🎵 **Musique** : Crée une boucle de 4 accords qui évoque un lever de soleil. Commence en mineur, termine en majeur.",
      "✍️ **Écriture** : Écris un micro-poème de 6 mots sur le thème de la renaissance créative.",
      "📚 **BD** : Dessine une planche muette où un personnage découvre un monde en noir et blanc qui prend vie couleur par couleur.",
    ];
    reply = "Voici quelques idées pour t'inspirer :\n\n" + ideas.join("\n\n");
  } else if (lastMessage.includes("merci")) {
    reply = "Avec plaisir ! 🎨 Continue de créer, l'art est un voyage sans fin. N'hésite pas si tu as besoin d'autres idées !";
  } else if (lastMessage.includes("feedback") || lastMessage.includes("retour") || lastMessage.includes("avis")) {
    reply = "Bien sûr ! Pour te donner un retour pertinent, pourrais-tu me décrire un peu ton œuvre ?\n\n"
      + "🎨 **Pour une œuvre visuelle** : Parle-moi des couleurs, de la composition.\n"
      + "🎵 **Pour de la musique** : Décris l'ambiance, le rythme.\n"
      + "✍️ **Pour un texte** : Partage quelques phrases.\n"
      + "📚 **Pour une BD** : Raconte-moi le concept.";
  } else if (lastMessage.includes("fonctionnalité") || lastMessage.includes("comment faire") || lastMessage.includes("aide")) {
    reply = "🎯 **Fonctionnalités Arteïa :**\n\n"
      + "📤 **Publier** : Œuvres visuelles, musique, écriture, BD\n"
      + "❤️ **Interagir** : Likes, commentaires, favoris\n"
      + "💬 **Chat** : Messages texte, vocaux, éphémères\n"
      + "🎵 **Musique** : Lecteur intégré avec upload\n"
      + "📖 **Lecture** : Mode immersif pour textes\n"
      + "🏆 **Défis** : Quêtes créatives hebdomadaires\n\n"
      + "Que souhaites-tu explorer ?";
  } else if (lastMessage.includes("exercice") || lastMessage.includes("défi") || lastMessage.includes("challenge")) {
    reply = "🔥 **Défi créatif du jour :**\n\n"
      + "**« 10 minutes chrono »** ⏱️\n\n"
      + "Prends un thème au hasard (nature, ville, rêve, émotion) et crée quelque chose en seulement 10 minutes.\n\n"
      + "Pas de perfectionnisme ! L'objectif est de libérer ta créativité sans filtre. 🎨";
  } else if (lastMessage.includes("qui es-tu") || lastMessage.includes("tu fais")) {
    reply = "Je suis **Arteïa Muse** ✨, l'assistant créatif open source d'Arteïa !\n\n"
      + "Je fonctionne avec des modèles open source (Llama 3, Mistral) et une base de connaissances artistiques.\n\n"
      + "Je peux :\n"
      + "🎨 Générer des idées artistiques\n"
      + "💡 Donner des retours sur tes créations\n"
      + "📚 Suggérer des techniques et exercices\n"
      + "🔍 T'expliquer les fonctionnalités de l'app";
  } else {
    reply = "Je suis Arteïa Muse ✨, ton assistant créatif open source !\n\nJe peux :\n"
      + "🎨 Générer des idées artistiques\n"
      + "💡 Donner des retours sur tes créations\n"
      + "📚 Suggérer des techniques et exercices\n"
      + "🔍 T'expliquer les fonctionnalités de l'app\n\n"
      + "De quoi as-tu besoin pour créer aujourd'hui ?";
  }

  return new Response(JSON.stringify({ reply }), {
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}