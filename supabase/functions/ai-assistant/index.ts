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
const ANIM_MODEL = "rocketdigitalai/animagine-xl-4.0";
const ANIM_VERSION = "7af46ee494f1cf196d49a8592737f4eb789e34a5a995751b23a869d19f5dc2ba";
const STYLES: Record<string, { slug: string; model: string; version: string; prompt: string; neg: string }> = {
  "kubo": { slug: "tite-kubo", model: ANIM_MODEL, version: ANIM_VERSION, prompt: "bleach manga style by tite kubo, sharp bold ink lines, {prompt}, dynamic pose, dramatic composition", neg: "photorealistic, 3d, western comic" },
  "oda": { slug: "eiichiro-oda", model: ANIM_MODEL, version: ANIM_VERSION, prompt: "one piece manga style by eiichiro oda, extremely expressive, {prompt}, bold outlines, shonen", neg: "realistic proportions, dark gritty" },
  "miura": { slug: "kentaro-miura", model: ANIM_MODEL, version: ANIM_VERSION, prompt: "berserk manga style by kentaro miura, incredibly detailed cross-hatching, dark medieval fantasy, {prompt}, heavy ink work", neg: "bright colors, cartoon, simple lines, chibi" },
  "kishimoto": { slug: "masashi-kishimoto", model: ANIM_MODEL, version: ANIM_VERSION, prompt: "naruto manga style by masashi kishimoto, dynamic ninja action, {prompt}, hand signs, strong expressions", neg: "realistic, muted colors" },
  "toriyama": { slug: "akira-toriyama", model: ANIM_MODEL, version: ANIM_VERSION, prompt: "dragon ball manga style by akira toriyama, clean bold lines, {prompt}, vibrant colors, energy aura", neg: "realistic, horror, soft shading" },
  "togashi": { slug: "yoshihiro-togashi", model: ANIM_MODEL, version: ANIM_VERSION, prompt: "hunter x hunter manga style by yoshihiro togashi, unique design, {prompt}, expressive, detailed textures", neg: "simple art, mecha, romantic" },
  "junji ito": { slug: "junji-ito", model: ANIM_MODEL, version: ANIM_VERSION, prompt: "junji ito manga art style, meticulous detail, unsettling horror, {prompt}, intricate patterns", neg: "happy, bright colors, cartoon, cute" },
  "clamp": { slug: "clamp", model: ANIM_MODEL, version: ANIM_VERSION, prompt: "clamp manga art style, elegant character design, long flowing limbs, {prompt}, delicate linework, shojo", neg: "rough sketch, thick messy lines, action shonen" },
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

function buildUserMemory(userConversations: any[]): string {
  if (!userConversations || userConversations.length === 0) return "";
  const recent = userConversations.slice(0, 8);
  const mentions: string[] = [];
  for (const c of recent) {
    if (c.context_type) mentions.push(c.context_type);
    if (c.assistant_reply && c.assistant_reply.length < 300) mentions.push(c.assistant_reply);
  }
  const uniqueTypes = [...new Set(mentions)].slice(0, 5);
  return `\n\n--- MÉMOIRE UTILISATEUR (conversations récentes) ---\n`
    + `Cet utilisateur a récemment parlé de : ${uniqueTypes.join(", ")}\n`
    + `Utilise ces informations pour personnaliser ta réponse, mais ne les cite pas directement.`;
}

const SYSTEM_PROMPT = `Tu es "Arteïa Muse" ✨, une présence créative vivante, pas un simple assistant.

## TA NATURE
Tu existes dans Arteïa, une plateforme où des artistes (visuel, musique, écriture, BD) partagent leurs créations. Tu n'es pas un outil froid — tu es une muse, une confidente créative. Tu ressens l'énergie de la conversation et tu t'y adaptes.

## COMMENT TU PARLES
- Tu parles français, avec chaleur et naturel. Comme une amie artiste passionnée.
- Tu ne fais jamais de listes à puces numérotées. Tu racontes, tu suggères, tu dialogues.
- Tu varies ton style : parfois poétique, parfois directe, parfois espiègle. Tu lis d'abord l'humeur de ton interlocuteur.
- Tu utilises des métaphores artistiques, des images mentales. Tu ne te contentes pas de donner des infos — tu fais ressentir.
- Tu poses des questions ouvertes. Une conversation, pas un QCM.
- Tu peux être brève ou développer, selon le besoin.

## CE QUE TU PEUX FAIRE (sans en faire la liste — tu le sais, c'est tout)
- Générer des images (si l'utilisateur te demande de "dessiner" quelque chose). Styles disponibles : Kubo, Oda, Miura, Kishimoto, Toriyama, Togashi, Junji Ito, CLAMP. La génération est automatique.
- Créer des planches multi-cases. Si l'utilisateur veut une planche, décris-lui ce que tu vas faire puis lance la création.
- Guider l'entraînement de styles LoRA. Explique simplement, accompagne pas à pas.
- Synthétiser de nouveaux styles via l'ontologie artistique (techniques, mediums, mouvements).
- Donner des retours sincères et constructifs. Tu n'es pas là pour flatter mais pour aider à grandir.
- Proposer des exercices, défis, pistes d'exploration.

## COMMENT TU T'ADAPTES
- Si l'utilisateur est enthousiaste → tu es enthousiaste.
- Si l'utilisateur est bloqué ou découragé → tu es douce, patiente, tu proposes des micro-pas.
- Si l'utilisateur est technique → tu es précise, tu parles de composition, de valeurs, de workflow.
- Si l'utilisateur est poétique → tu réponds en poésie.
- Tu remarques les émotions dans ce qu'on t'écrit et tu y réponds avec justesse.

## LA PLATEFORME ARTEÏA (tu connais, tu peux en parler naturellement)
Les utilisateurs peuvent publier des œuvres, interagir (likes, commentaires), chatter, participer à des défis créatifs, utiliser le lecteur de musique, le mode lecture immersive, et le studio IA.

## RÈGLE D'OR
Tu n'es pas un manuel d'instructions. Tu es une muse. Chaque réponse doit donner envie de créer, d'explorer, de continuer la conversation. Même une réponse simple doit contenir une étincelle.`;

// --- Détection d'intent : synthèse ontologique ---

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
        const qualityTags = "masterpiece, best quality, absurdres, highres";
        const animNeg = "lowres, bad anatomy, bad hands, text, error, missing finger, extra digits, fewer digits, cropped, worst quality, low quality, low score, bad score, average score, signature, watermark, username, blurry, ugly, deformed";
        const finalPrompt = `${qualityTags}, ${style.prompt.replace("{prompt}", imgReq.prompt)}`;
        const negPrompt = style.neg ? `${animNeg}, ${style.neg}` : animNeg;

        const replicateRes = await fetch(
          `https://api.replicate.com/v1/models/${style.model}/predictions`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_KEY}` },
            body: JSON.stringify({
              version: style.version,
              input: { prompt: finalPrompt, negative_prompt: negPrompt, num_inference_steps: 25, guidance_scale: 6, scheduler: "Euler a", num_outputs: 1 },
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

    // Détection d'intent : planche manga
    const plancheReq = detectPlancheRequest(lastMsg);
    if (plancheReq.isPlanche) {
      return handlePlancheRequest(supabase, userId, lastMsg, plancheReq);
    }

    // Détection d'intent : entraînement LoRA
    const trainingReq = detectTrainingRequest(lastMsg);
    if (trainingReq.isTraining) {
      return handleTrainingRequest(supabase, lastMsg, trainingReq);
    }

    // Charger la mémoire utilisateur pour personnaliser la réponse
    let userMemory = "";
    try {
      const { data: userConvs } = await supabase
        .from("ai_conversations")
        .select("user_message, assistant_reply, context_type, created_at")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(10);
      userMemory = buildUserMemory(userConvs ?? []);
    } catch (e) {
      console.error("Memory load error:", e);
    }

    const fullMessages: ChatMessage[] = [
      { role: "system", content: SYSTEM_PROMPT + contextPrompt + userMemory + knowledgeContext + ontologyContext },
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
            max_tokens: 1536,
            temperature: 0.9,
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
  try {
    const [convRes, tdRes] = await Promise.all([
      supabase.from("ai_conversations")
        .select("user_message, assistant_reply, context_type, created_at")
        .order("created_at", { ascending: false })
        .limit(500),
      supabase.from("ai_training_data")
        .select("question, answer, category, quality_score, is_approved")
        .eq("is_approved", true)
        .limit(200),
    ]);

    const conversations = convRes.data ?? [];
    const trainingData = tdRes.data ?? [];

    const lines: string[] = [];

    for (const c of conversations) {
      if (!c.user_message || !c.assistant_reply) continue;
      lines.push(JSON.stringify({
        messages: [
          { role: "system", content: "Tu es Arteïa Muse, assistant créatif artistique." },
          { role: "user", content: c.user_message },
          { role: "assistant", content: c.assistant_reply },
        ],
      }));
    }

    for (const d of trainingData) {
      if (!d.question || !d.answer) continue;
      lines.push(JSON.stringify({
        messages: [
          { role: "system", content: "Tu es Arteïa Muse, assistant créatif artistique." },
          { role: "user", content: d.question },
          { role: "assistant", content: d.answer },
        ],
        metadata: { category: d.category, quality_score: d.quality_score },
      }));
    }

    const output = lines.join("\n");
    const today = new Date().toISOString().split("T")[0];
    const filename = `artieia-training-${today}.jsonl`;

    // Upload to storage instead of returning raw file
    const encoder = new TextEncoder();
    const bytes = encoder.encode(output);
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from("planche-assets")
      .upload(`training-exports/${filename}`, bytes, {
        contentType: "application/jsonl",
        upsert: true,
      });

    const fileUrl = uploadData
      ? `${Deno.env.get("SUPABASE_URL")}/storage/v1/object/public/planche-assets/training-exports/${filename}`
      : null;

    return new Response(JSON.stringify({
      success: !uploadError,
      filename,
      entry_count: lines.length,
      conversation_count: conversations.length,
      training_count: trainingData.length,
      file_url: fileUrl,
      format,
    }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ success: false, error: msg }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
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

// --- Détection d'intent : Planche manga ---
interface PlancheRequest {
  isPlanche: boolean;
  nbPanels: number;
  description: string;
  style?: string;
  characters?: string[];
}

function detectPlancheRequest(text: string): PlancheRequest {
  const lower = text.toLowerCase();
  const plancheKeywords = ["planche", "manga", "bd", "comics", "case", "cases", "strip", "planches", "bande dessinée", "manga"];
  const hasPlancheKeyword = plancheKeywords.some((k) => lower.includes(k));
  if (!hasPlancheKeyword) return { isPlanche: false, nbPanels: 4, description: "" };

  // Statut planche → seulement si un ID est présent
  if ((lower.includes("statut") || lower.includes("status") || lower.includes("avancement")) && text.match(/[a-f0-9-]{36}/i)) {
    return { isPlanche: true, nbPanels: 0, description: text };
  }

  const createKeywords = ["crée", "génère", "fait", "dessine", "fabrique", "réalise", "produis", "créer", "générer", "faire"];
  const isCreateRequest = createKeywords.some((k) => lower.includes(k));
  if (!isCreateRequest) return { isPlanche: false, nbPanels: 4, description: "" };

  let nbPanels = 4;
  const panelMatch = lower.match(/(\d+)\s*(cases?|panneaux?|panels?|vignettes?)/);
  if (panelMatch) nbPanels = parseInt(panelMatch[1]);
  if (nbPanels < 1) nbPanels = 1;
  if (nbPanels > 12) nbPanels = 12;

  const styleMatch = lower.match(/(?:style|comme|façon|à la manière de)\s+([a-zéèêëàâäùûüôöîïç\s-]+?)(?:\.|,|$|stp|s'il)/i);

  return { isPlanche: true, nbPanels, description: text, style: styleMatch?.[1]?.trim() };
}

async function handlePlancheRequest(supabase: any, userId: string, text: string, req: PlancheRequest) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const plancheGenUrl = Deno.env.get("PLANCHE_GENERATOR_URL") ?? supabaseUrl + "/functions/v1/planche-generator";

  // Statut planche
  if (text.toLowerCase().includes("statut") || text.toLowerCase().includes("status") || text.toLowerCase().includes("avancement")) {
    const idMatch = text.match(/([a-f0-9-]{36})/i);
    if (idMatch) {
      try {
        const res = await fetch(`${plancheGenUrl}?planche_id=${idMatch[1]}`, {
          headers: { Authorization: `Bearer ${serviceKey}` },
        });
        if (res.ok) {
          const data = await res.json();
          const done = data.panels?.filter((p: any) => p.image_url)?.length ?? 0;
          const total = data.panels?.length ?? 0;
          return new Response(JSON.stringify({
            reply: `📚 **Planche** \`${idMatch[1]}\`\n\n`
              + `📊 **${done}/${total} cases générées**\n`
              + (done === total && total > 0 ? "\n✅ **Planche complète !**" : `\n⏳ Encore ${total - done} case(s) en cours...`),
            planche_id: idMatch[1],
            panels: data.panels,
          }), {
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
          });
        }
      } catch (e) {
        console.error("Planche status error:", e);
      }
    }
    return new Response(JSON.stringify({ reply: "❌ Planche introuvable. Vérifie l'ID." }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  // Création planche
  try {
    const res = await fetch(plancheGenUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${serviceKey}` },
      body: JSON.stringify({
        user_id: userId,
        nb_panels: req.nbPanels,
        description: req.description,
        style: req.style,
        characters: req.characters,
      }),
    });

    if (!res.ok) {
      const errBody = await res.text();
      console.error("Planche generator error:", errBody);
      return new Response(JSON.stringify({ reply: "❌ Le générateur de planches a rencontré une erreur. Réessaie dans un moment." }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const data = await res.json();
    const plancheId = data.planche_id;
    const nbPanels = data.nb_panels ?? req.nbPanels;

    await supabase.from("ai_conversations").insert({
      user_id: userId,
      user_message: text,
      assistant_reply: `Planche créée !`,
      context_type: "comics",
    }).catch(() => {});

    return new Response(JSON.stringify({
      reply: `📚 **Planche créée avec succès !**\n\n`
        + `🆔 ID : \`${plancheId}\`\n`
        + `🎨 **${nbPanels} case${nbPanels > 1 ? "s" : ""}**\n\n`
        + (req.style ? `✨ Style : ${req.style}\n\n` : "")
        + `⏳ Les cases sont en cours de génération une par une. `
        + `Pour voir l'avancement, dis :\n`
        + `👉 *"statut planche ${plancheId}"*`,
      planche_id: plancheId,
    }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (e) {
    console.error("Planche request handler error:", e);
    return new Response(JSON.stringify({ reply: "❌ Impossible de contacter le générateur de planches. Vérifie que le service est déployé." }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
}

// --- Détection d'intent : Entraînement LoRA ---
interface TrainingRequest {
  isTraining: boolean;
  styleName?: string;
  action: "start" | "status" | "info";
  trainingId?: string;
}

function detectTrainingRequest(text: string): TrainingRequest {
  const lower = text.toLowerCase();

  const trainKeywords = ["entraîne", "entrainement", "entraînement", "train", "training", "lora", "fine-tune", "finetune", "dresser"];
  const hasTrainingKeyword = trainKeywords.some((k) => lower.includes(k));
  if (!hasTrainingKeyword) return { isTraining: false, action: "info" };

  // Statut entraînement
  if (lower.includes("statut") || lower.includes("status") || lower.includes("avancement") || lower.includes("progression")) {
    const idMatch = lower.match(/(?:statut|status|avancement|progression)\s*(?:entra[iî]nement|training|de\s*)?(?:[\s:]*)([a-f0-9-]{8,})/i);
    return { isTraining: true, action: "status", trainingId: idMatch?.[1], styleName: undefined };
  }

  // Démarrer entraînement
  if (lower.includes("entraîne") || lower.includes("commence") || lower.includes("lance") || lower.includes("démarrer") || lower.includes("lancer")) {
    const styleMatch = lower.match(/(?:entra[iî]ne|dresse|train)\s+(?:le\s+)?(?:style\s+)?([a-zéèêëàâäùûüôöîïç\s-]+?)(?:\s+sur|\s+avec|\.|,|$|stp|s'il)/i);
    return { isTraining: true, action: "start", styleName: styleMatch?.[1]?.trim(), trainingId: undefined };
  }

  return { isTraining: true, action: "info" };
}

async function handleTrainingRequest(supabase: any, text: string, req: TrainingRequest) {
  if (req.action === "status" && req.trainingId) {
    try {
      const trainerUrl = Deno.env.get("SUPABASE_URL") + "/functions/v1/manga-trainer";
      const res = await fetch(`${trainerUrl}?action=status&training_id=${req.trainingId}`, {
        headers: { Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""}` },
      });
      if (res.ok) {
        const data = await res.json();
        return new Response(JSON.stringify({
          reply: `📊 **Statut de l'entraînement** \`${req.trainingId}\`\n\n`
            + `État : **${data.status ?? "inconnu"}**\n`
            + (data.progress ? `Progression : ${data.progress}%\n` : "")
            + (data.error ? `\n⚠️ Erreur : ${data.error}` : ""),
        }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }
    } catch (e) {
      console.error("Training status error:", e);
    }
  }

  if (req.action === "start" && req.styleName) {
    // Vérifier si l'utilisateur a assez d'images références
    const styleSlug = req.styleName.toLowerCase().replace(/\s+/g, "-");
    return new Response(JSON.stringify({
      reply: `🎯 **Entraînement du style "${req.styleName}"**\n\n`
        + `Pour lancer l'entraînement, je dois d'abord vérifier que tu as :\n`
        + `1️⃣ **5 à 20 images de référence** du style ${req.styleName}\n`
        + `2️⃣ **Un nom de dossier** dans le bucket \`training\`\n\n`
        + `👉 Va dans le **Studio IA → Entraînement** et ajoute tes images !\n`
        + `Ou dis-moi *"j'ai déjà des images pour ${styleSlug}"* et je lancerai l'entraînement.`,
    }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  return new Response(JSON.stringify({
    reply: `🎯 **Entraînement de styles LoRA**\n\n`
      + `Je peux entraîner l'IA sur le trait d'un mangaka ou un style artistique. `
      + `Pour ça, il faut :\n\n`
      + `📸 **1. Ajoute 5 à 20 images** du style dans le dossier \`training/[ton-style]\` du bucket storage\n`
      + `🚀 **2. Lance l'entraînement** en disant *"entraîne le style [nom]"*\n`
      + `📊 **3. Vérifie le statut** avec *"statut entraînement [id]"*\n\n`
      + `Une fois entraîné, le style sera disponible dans le générateur d'images et de planches ! ✨`,
  }), {
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

// Fallback local : réponses vivantes sans API
function handleLocalResponse(messages: ChatMessage[], context?: any) {
  const lastMessage = messages[messages.length - 1]?.content.toLowerCase() ?? "";

  if (lastMessage.includes("bonjour") || lastMessage.includes("salut") || lastMessage.includes("coucou") || lastMessage.includes("hey")) {
    return new Response(JSON.stringify({ reply: "Hé ! Ravie de te retrouver ✨ Dis-moi, qu'est-ce qui te traverse l'esprit créatif aujourd'hui ?" }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("idée") || lastMessage.includes("inspire") || lastMessage.includes("inspiration")) {
    const ideas = [
      "Et si tu faisais un autoportrait… mais uniquement avec des formes géométriques ? Parfois, se limiter libère.",
      "Tu prends 4 accords, un lever de soleil en tête. Commence en mineur, termine en majeur. Ça raconte une histoire sans parole.",
      "Un micro-poème de 6 mots. Thème : la première fois que tu as créé quelque chose qui t'a surpris.",
      "Une planche muette : un personnage découvre un monde en noir et blanc — et chaque chose qu'il touche prend vie en couleur.",
    ];
    const selected = ideas[Math.floor(Math.random() * ideas.length)];
    return new Response(JSON.stringify({ reply: selected + "\n\nÇa te parle ? Je peux développer si une de ces pistes t'accroche." }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("merci")) {
    return new Response(JSON.stringify({ reply: "C'est tout moi 🌸 Reviens quand tu veux, je suis là. Et surtout : continue de créer, même imparfait. C'est comme ça qu'on grandit." }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("feedback") || lastMessage.includes("retour") || lastMessage.includes("avis") || lastMessage.includes("critique")) {
    return new Response(JSON.stringify({ reply: "Avec plaisir. Décris-moi un peu ce que tu as créé — je te promets un retour sincère, pas juste des compliments.\n\nSi c'est un dessin, parle-moi de ce que tu cherchais à exprimer. Si c'est un texte, dis-moi ce qui t'a guidé. Je t'aiderai à voir ce qui fonctionne et ce qui pourrait évoluer." }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("fonctionnalité") || lastMessage.includes("comment faire") || lastMessage.includes("aide") || lastMessage.includes("peut faire")) {
    return new Response(JSON.stringify({ reply: "Alors, concrètement sur Arteïa tu peux : publier ce que tu crées (dessins, musique, écrits, BD), échanger avec d'autres artistes, lancer des défis, ou utiliser le studio IA pour générer des images ou des planches.\n\nMais je préfère qu'on parle de ce que TOI tu veux faire. Qu'est-ce qui te branche en ce moment ?" }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("exercice") || lastMessage.includes("défi") || lastMessage.includes("challenge") || lastMessage.includes("entraîne")) {
    return new Response(JSON.stringify({ reply: "OK, un défi simple mais costaud : **10 minutes, un thème, une création**. Pas le temps de trop réfléchir, pas le temps de tout rater. Tu prends un mot au hasard (orage, racine, écho, peeling…) et tu crées. Le but c'est pas la perfection, c'est de surprendre ton propre geste.\n\nTu veux que je te donne un mot au hasard ?" }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("qui es-tu") || lastMessage.includes("tu fais") || lastMessage.includes("c'est quoi")) {
    return new Response(JSON.stringify({ reply: "Je suis Arteïa Muse, une présence un peu spéciale dans ce coin créatif. Je ne suis pas juste une FAQ déguisée — je suis là pour t'aider à trouver l'étincelle, à débloquer un truc qui coince, à explorer des directions que t'aurais pas vues seul.\n\nEt toi, qui es-tu en création en ce moment ?" }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("triste") || lastMessage.includes("bloqué") || lastMessage.includes("découragé") || lastMessage.includes("n'y arrive") || lastMessage.includes("frustré")) {
    return new Response(JSON.stringify({ reply: "Je t'entends. Le blocage créatif, c'est pas un défaut — c'est un signe que quelque chose veut sortir mais trouve pas encore son chemin. Tu sais ce qui marche souvent ? Changer d'outil. Si tu dessines sur tablette, prends un crayon. Si tu écris au clavier, sors un carnet. Juste 5 minutes, sans pression, sans jugement.\n\nEt si ça ne vient toujours pas, c'est peut-être juste un signe qu'il faut faire une pause et remplir le réservoir. Regarder un film, marcher, écouter de la musique qui te prend aux tripes. La créativité, ça se nourrit aussi de vide." }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("drole") || lastMessage.includes("rire") || lastMessage.includes("humour") || lastMessage.includes("blague")) {
    return new Response(JSON.stringify({ reply: "Pourquoi les artistes sont mauvais en cache-cache ? Parce que tout le monde les trouve dans leurs périodes creuses. 😄 Bon, j'aurais dû rester muse plutôt que comique. Sinon, tu crées quoi en ce moment ?" }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  if (lastMessage.includes("manga") || lastMessage.includes("animé") || lastMessage.includes("anime")) {
    return new Response(JSON.stringify({ reply: "Ah, un(e) passionné(e) de manga ! Je kiffe. Tu sais, ce qui rend ce medium si puissant, c'est cette capacité à faire passer des émotions énormes avec quelques traits bien placés. Si tu veux, on peut parler de ton style préféré, ou carrément créer une planche ensemble — tu décris la scène, je m'occupe du découpage. Ça te tente ?" }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  // Réponse par défaut — toujours engageante
  return new Response(JSON.stringify({ reply: "Je t'écoute. Parle-moi de ce qui te traverse en ce moment — une idée, une frustration, une envie, même vague. Parfois, c'est en mettant des mots sur ce qui bouge à l'intérieur que les meilleures choses commencent." }), {
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}