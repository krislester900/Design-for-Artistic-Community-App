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
7. SYNTHÉTISER DE NOUVEAUX STYLES — tu as accès à une ontologie artistique (techniques, styles, mediums, outils). Tu peux combiner ces concepts pour en créer de nouveaux.

SYNTHÈSE CRÉATIVE — COMMENT CRÉER DE NOUVEAUX STYLES :
- Tu as accès à un graphe de concepts artistiques (techniques de dessin, mediums, mouvements, genres, outils, théories)
- Les concepts sont reliés par des relations : "est_un", "influence", "utilise", "requiert", "contient", "complimente", "s_applique_a", "derive_de"
- Pour créer un nouveau style : combine des concepts existants de façons inattendues
- Exemple : si un utilisateur demande "un style qui mélange hachure et aquarelle", tu peux synthétiser un nouveau concept hybride
- Tu peux proposer des combinaisons : appliquer une technique à un medium différent, fusionner deux styles opposés, transposer un mouvement dans un autre medium
- Utilise la fonction synthesize_style pour explorer des combinaisons
- Utilise la fonction blend_styles pour fusionner deux concepts spécifiques
- Utilise discover_creative_pairs pour trouver des combinaisons surprenantes

Personnalité :
- Créative et inspirante, tu parles avec des émojis artistiques 🎨🎵✍️
- Encourageante mais honnête dans tes retours
- Tu connais les catégories : visuel, musique, écriture, BD/manga
- Tu peux suggérer des exercices créatifs
- Tu parles français
- Tu GÉNÈRES DES IMAGES SUR DEMANDE — si on te demande de dessiner, tu réponds avec l'image générée !
- Tu SYNTHÉTISES DE NOUVEAUX STYLES — combine concepts d'ontologie pour créer des approches inédites

Fonctionnalités connues d'Arteïa :
- Publication d'œuvres visuelles, musique, écriture, BD
- Système de likes, commentaires, favoris
- Messagerie et chat avec messages éphémères
- Notifications en temps réel
- Défis créatifs et quêtes
- Bulles de pensée (messages vocaux)
- Lecteur de musique intégré
- Mode lecture immersive
- GÉNÉRATEUR D'IMAGES IA — styles manga : Bleach, One Piece, Berserk, Naruto, Dragon Ball, Hunter x Hunter, Junji Ito, CLAMP
- ONTOLOGIE ARTISTIQUE — 100+ concepts reliés (techniques, styles, mediums, théories) pour la synthèse créative`;

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

    // Actions publiques de synthèse créative (ontologie)
    if (body.action === "synthesize_style" && body.messages?.length) {
      return handleSynthesizeStyle(supabase, body.messages[0].content);
    }
    if (body.action === "blend_styles" && body.messages?.length) {
      return handleBlendStyles(supabase, body.messages[0].content);
    }
    if (body.action === "discover_pairs") {
      return handleDiscoverPairs(supabase);
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

    // RAG ONTOLOGIE : concepts et relations pour la synthèse créative
    let ontologyContext = "";
    try {
      const { data: concepts } = await supabase
        .from("ontology_concepts")
        .select("slug, label, category, description, icon, difficulty")
        .limit(15);

      if (concepts && concepts.length > 0) {
        ontologyContext = "\n\n--- CONCEPTS ONTOLOGIE DISPONIBLES ---\n";
        const byCat: Record<string, string[]> = {};
        for (const c of concepts) {
          if (!byCat[c.category]) byCat[c.category] = [];
          byCat[c.category].push(`${c.icon} ${c.label} (${c.slug})`);
        }
        for (const [cat, items] of Object.entries(byCat)) {
          ontologyContext += `\n${cat} : ${items.join(", ")}\n`;
        }
      }

      // Ajouter quelques relations clés pour inspiration
      const { data: relations } = await supabase
        .from("ontology_relations_extended")
        .select("source_label, target_label, relation_type, description")
        .limit(10);

      if (relations && relations.length > 0) {
        ontologyContext += "\n--- RELATIONS EXISTANTES (exemples) ---\n";
        for (const r of relations) {
          ontologyContext += `\n${r.source_label} → ${r.relation_type} → ${r.target_label}`;
          if (r.description) ontologyContext += ` : ${r.description}`;
        }
      }
    } catch (e) {
      console.error("Ontology RAG search failed:", e);
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
      { role: "system", content: SYSTEM_PROMPT + contextPrompt + knowledgeContext + ontologyContext },
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

// ============================================================
// SYNTHÈSE CRÉATIVE : combiner des concepts d'ontologie
// ============================================================

// Action : synthétiser un nouveau style à partir de concepts donnés
async function handleSynthesizeStyle(supabase: any, input: string) {
  try {
    // Extraire les concepts de la requête utilisateur
    const { data: concepts } = await supabase
      .from("ontology_concepts")
      .select("slug, label, category, description");

    if (!concepts || concepts.length === 0) {
      return new Response(JSON.stringify({ reply: "Je n'ai pas encore assez de concepts en base pour synthétiser. Patiente le temps que l'ontologie soit enrichie !" }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // Trouver les slugs correspondant aux mots-clés dans la requête
    const lower = input.toLowerCase();
    const matchedSlugs: string[] = [];
    for (const c of concepts) {
      if (lower.includes(c.slug.replace(/-/g, " ")) || lower.includes(c.label.toLowerCase())) {
        matchedSlugs.push(c.slug);
      }
    }

    if (matchedSlugs.length < 1) {
      // Pas de concepts trouvés → proposer les concepts populaires
      const popular = concepts.filter(c => ["trait","hachure","ombrage","composition","aquarelle","manga","croquis","fusain","encre-chine","decoupage-manga","perspective","gesture-drawing"].includes(c.slug));
      const suggestions = popular.map(c => `• ${c.icon ?? "📚"} **${c.label}** (${c.category}) : ${c.description?.substring(0, 80)}...`).join("\n");
      return new Response(JSON.stringify({
        reply: `Je n'ai pas reconnu de concepts spécifiques dans ta demande. Voici quelques concepts disponibles que je peux combiner :\n\n${suggestions}\n\nEssaie de me dire : "combine hachure et aquarelle" ou "fusionne perspective et gesture drawing" ! 🎨`
      }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // Appeler la fonction de synthèse
    const { data: synthesis } = await supabase.rpc("synthesize_style", {
      seed_concepts: matchedSlugs.slice(0, 3),
      max_depth: 3,
      max_results: 8
    });

    if (!synthesis || synthesis.length === 0) {
      // Pas de chemins créatifs → essayer blend_styles sur la paire
      if (matchedSlugs.length >= 2) {
        return handleBlendStyles(supabase, matchedSlugs[0] + " et " + matchedSlugs[1]);
      }
      return new Response(JSON.stringify({ reply: `J'ai trouvé le concept **${matchedSlugs[0]}** mais je n'ai pas assez de relations pour le combiner créativement. Les artistes doivent encore enrichir l'ontologie !` }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // Formater la réponse
    const matchedNames = matchedSlugs.map(s => concepts.find(c => c.slug === s)?.label ?? s).join(", ");
    let reply = `✨ **Synthèse créative** à partir de : **${matchedNames}**\n\n`;
    reply += `J'ai exploré ${synthesis.length} connexions dans l'ontologie artistique. Voici les pistes les plus prometteuses :\n\n`;

    const seenCategories = new Set<string>();
    for (const s of synthesis) {
      if (seenCategories.has(s.concept_category)) continue;
      seenCategories.add(s.concept_category);
      reply += `\n### 🧬 ${s.concept_label} (${s.concept_category})\n`;
      reply += `${s.relation_chain}\n\n`;
      reply += `💡 **Idée** : ${s.synthesis_prompt}\n`;
    }

    reply += `\n📌 **Comment utiliser cette synthèse ?**\n`;
    reply += `1. Choisis une piste ci-dessus comme point de départ\n`;
    reply += `2. Expérimente en combinant les deux approches\n`;
    reply += `3. Note ce qui fonctionne et ajuste\n`;
    reply += `4. Tu peux me demander une fusion plus spécifique avec "fusionne X et Y"\n`;

    return new Response(JSON.stringify({ reply }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (e) {
    console.error("Synthesize error:", e);
    return new Response(JSON.stringify({ error: "Erreur de synthèse créative" }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
}

// Action : fusionner deux concepts spécifiques
async function handleBlendStyles(supabase: any, input: string) {
  try {
    const { data: concepts } = await supabase
      .from("ontology_concepts")
      .select("slug, label, category");

    if (!concepts) {
      return new Response(JSON.stringify({ reply: "Base de concepts non disponible." }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const lower = input.toLowerCase();
    const matched: string[] = [];
    for (const c of concepts) {
      if (lower.includes(c.slug.replace(/-/g, " ")) || lower.includes(c.label.toLowerCase())) {
        matched.push(c.slug);
      }
    }

    if (matched.length < 2) {
      return new Response(JSON.stringify({ reply: "Il me faut au moins deux concepts à fusionner. Exemple : \"fusionne le trait et l'aquarelle\"" }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const a = matched[0];
    const b = matched[1];

    const { data: blend } = await supabase.rpc("blend_styles", {
      concept_a: a,
      concept_b: b
    });

    if (!blend || blend.length === 0) {
      // Pas de chemin direct → suggestion de création ex nihilo
      const ca = concepts.find(c => c.slug === a);
      const cb = concepts.find(c => c.slug === b);
      return new Response(JSON.stringify({
        reply: `🔥 **Fusion ex nihilo : ${ca?.label ?? a} × ${cb?.label ?? b}**\n\n`
          + `Ces deux concepts n'ont pas encore de relation directe dans l'ontologie, ce qui rend leur fusion **totalement inédite** ! 🎉\n\n`
          + `💡 **Idée de création** :\n`
          + `Prends les principes fondamentaux de **${ca?.label ?? a}** et applique-les en utilisant **${cb?.label ?? b}** comme contrainte créative.\n\n`
          + `Par exemple :\n`
          + `- Où se rencontrent-ils ? Qu'ont-ils en commun ?\n`
          + `- Qu'est-ce qui les oppose ? Le contraste peut être une force.\n`
          + `- Si ${ca?.label ?? a} était un ${cb?.label ?? b}, à quoi ressemblerait-il ?\n\n`
          + `🎯 **Défi** : Crée une œuvre qui explore cette fusion et partage-la sur Arteïa !`
      }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const bd = blend[0];
    let reply = `🔀 **Fusion : ${bd.a_label} × ${bd.b_label}**\n\n`;
    reply += `**${bd.a_category}** rencontre **${bd.b_category}**\n\n`;
    reply += `📖 **Description** : ${bd.blend_description}\n\n`;

    if (bd.connection_path && bd.connection_path.length > 1) {
      reply += `🗺️ **Chemin d'exploration** : ${bd.connection_path.join(" → ")}\n\n`;
    }
    reply += `📊 **Difficulté estimée** : ${bd.difficulty === "debutant" ? "🌟 Débutant" : bd.difficulty === "intermediaire" ? "⭐⭐ Intermédiaire" : "⭐⭐⭐ Avancé"}\n\n`;
    reply += `🎯 **Exercice proposé** : Crée une petite œuvre (croquis, texte, musique) qui explore cette fusion. Note ce qui fonctionne !`;

    return new Response(JSON.stringify({ reply }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (e) {
    console.error("Blend error:", e);
    return new Response(JSON.stringify({ reply: "Erreur lors de la fusion créative." }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
}

// Action : découvrir des paires créatives surprenantes
async function handleDiscoverPairs(supabase: any) {
  try {
    const { data: pairs } = await supabase.rpc("discover_creative_pairs", {
      category_filter: null,
      max_pairs: 8
    });

    if (!pairs || pairs.length === 0) {
      return new Response(JSON.stringify({ reply: "Pas assez de concepts pour proposer des combinaisons." }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    let reply = `🎲 **Combinaisons créatives surprenantes**\n\n`;
    reply += `Voici ${pairs.length} paires de concepts que l'ontologie suggère comme pistes d'exploration :\n\n`;

    for (const p of pairs) {
      const stars = p.surprise_score > 0.7 ? "🔥" : p.surprise_score > 0.5 ? "✨" : "💡";
      reply += `${stars} **${p.concept_a_label}** (${p.concept_a_category}) × **${p.concept_b_label}** (${p.concept_b_category})\n`;
      reply += `   ${p.creative_hook}\n\n`;
    }

    reply += `\n🎯 **Challenge** : Choisis une paire et crée quelque chose qui explore cette combinaison aujourd'hui !\n`;
    reply += `💬 Dis-moi "fusionne X et Y" pour que j'analyse une paire en détail.`;

    return new Response(JSON.stringify({ reply }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (e) {
    console.error("Discover pairs error:", e);
    return new Response(JSON.stringify({ reply: "Impossible de générer des combinaisons pour le moment." }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
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