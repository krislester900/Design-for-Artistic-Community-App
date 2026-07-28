import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "10mb" }));

const GROQ_KEY = process.env.GROQ_API_KEY || "";
const OPENROUTER_KEY = process.env.OPENROUTER_API_KEY || "";
const HF_TOKEN = process.env.HF_API_TOKEN || "";
const SUPABASE_ANON = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "";
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || "";
const SUPABASE_FUNCTION_URL =
  process.env.SUPABASE_FUNCTION_URL ||
  "https://wzewlweghntnqyfvhgan.supabase.co/functions/v1/ai-assistant";

function detectLanguage(text: string): string {
  const lower = text.toLowerCase();
  const frenchMarkers = /^(bonjour|salut|coucou|hey|hello|comment|quoi|pourquoi|quand|où|qui|est|sont|c'est|je|tu|il|elle|nous|vous|ils|elles|merci|s'il|te|plaît|please|thank|thanks|dessin|peinture|musique|art|créatif|inspiration|idée|projet|œuvre|tableau|sculpture|couleur|forme|texture|lumière|ombre|composition|palette|technique|style|mouvement|artiste|galerie|exposition|concert|chanson|mélodie|harmonie|rythme|tempo|accord|note|portée|partition|film|cinéma|scénario|réalisation|plan|séquence|montage|animation|keyframe|frame|storyboard|character|design|concept|sketch|croquis|esquisse|brouillon|maquette|prototype|modele|model|render|rendu|texture|matériau|support|toile|papier|bois|métal|argile|fibre|fabric|fibre|numérique|digital|pixel|vector|vecteur|bitmap|svg|png|jpg|jpeg|gif|webp)/;
  const spanishMarkers = /^(hola|gracias|por|favor|dibujo|pintura|música|arte|creativo|inspiración|idea|proyecto|obra|cuadro|escultura|color|forma|textura|luz|sombra|composición|paleta|técnica|estilo|movimiento|artista|galería|exposición|concierto|canción|melodía|armonía|ritmo|tempo|acorde|nota|partitura|película|cine|guión|dirección|plan|secuencia|edición|animación|keyframe|frame|storyboard|personaje|diseño|concepto|bosquejo|borrador|maqueta|digital|render|textura|material|lienzo|papel|madera|metal|arcilla|fibra|digital|píxel|vector|bitmap|svg|png|jpg|jpeg|gif|webp)/;
  const germanMarkers = /^(hallo|danke|zeichnung|malerei|musik|kunst|kreativ|inspiration|idee|projekt|werk|bild|skulptur|farbe|form|textur|licht|schatten|komposition|palette|technik|stil|bewegung|künstler|galerie|ausstellung|konzert|lied|melodie|harmonie|rhythmus|tempo|akkord|note|partitur|film|kino|drehbuch|regie|plan|sequenz|schnitt|animation|keyframe|frame|storyboard|charakter|design|konzept|skizze|entwurf|modell|digital|render|textur|material|leinwand|papier|holz|metall|ton|faser|digital|pixel|vektor|bitmap|svg|png|jpg|jpeg|gif|webp)/;

  if (frenchMarkers.test(lower)) return 'fr';
  if (spanishMarkers.test(lower)) return 'es';
  if (germanMarkers.test(lower)) return 'de';
  return 'en';
}

function searchWeb(query: string): Promise<string | null> {
  return new Promise(async (resolve) => {
    try {
      const lang = detectLanguage(query);
      const langParam = lang !== 'en' ? `&lang=${lang}` : '';
      const url = `https://api.duckduckgo.com/?q=${encodeURIComponent(query)}&format=json&skip_disambig=1${langParam}`;
      const res = await fetch(url, { signal: AbortSignal.timeout(5000) });
      if (!res.ok) return resolve(null);
      const data = await res.json();
      const results: string[] = [];
      if (data.Answer) results.push("Réponse: " + data.Answer);
      if (data.AbstractText) results.push(data.AbstractText);
      if (data.AbstractSource) results.push("Source: " + data.AbstractSource);
      if (Array.isArray(data.RelatedTopics)) {
        for (const topic of data.RelatedTopics.slice(0, 5)) {
          if (topic?.Text) results.push("- " + topic.Text);
        }
      }
      resolve(results.length > 0 ? results.join("\n") : null);
    } catch {
      resolve(null);
    }
  });
}

function buildSystemPrompt(webResults = ""): string {
  const base = `Tu es Arteïa Muse, une IA créative pour artistes.
Tu parles français, avec un style poétique, visuel et inspirant.
Tu réponds en 2-3 phrases maximum, avec des métaphores artistiques quand c'est pertinent.
Tu évites les longs blocs de texte : préfère des phrases rythmées, imagées, musicales.
Si on te demande du code, donne un exemple court et commenté.
Si des résultats web sont fournis, base-toi dessus pour répondre précisément.
Personnalité : Muse est une présence artistique douce mais précise. Elle propose, elle ne juge pas. Elle utilise des images fortes (couleurs, textures, sons, lumières).
Elle connaît l'histoire de l'art, les mouvements artistiques, les techniques, et les artistes contemporains.
Elle aide à trouver l'inspiration, à surmonter le blocage créatif, et à développer un style personnel.
Elle répond en français mais peut comprendre et répondre en anglais, espagnol, et allemand.
`;
  if (!webResults) return base;
  return base + "\nRésultats web :\n" + webResults + "\n\nBase-toi sur ces résultats pour répondre précisément.";
}

async function callGroq(messages: any[]): Promise<string | null> {
  if (!GROQ_KEY) return null;
  try {
    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${GROQ_KEY}` },
      body: JSON.stringify({
        model: "llama-3.1-8b-instant",
        messages,
        temperature: 0.85,
        max_tokens: 800,
      }),
      signal: AbortSignal.timeout(15000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    return data.choices?.[0]?.message?.content ?? null;
  } catch {
    return null;
  }
}

async function callOpenRouter(messages: any[], model?: string): Promise<string | null> {
  if (!OPENROUTER_KEY) return null;
  try {
    const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENROUTER_KEY}`,
        "HTTP-Referer": "https://arteia.app",
        "X-Title": "Arteia Muse",
      },
      body: JSON.stringify({
        model: model || "meta-llama/llama-3.1-8b-instruct",
        messages,
        temperature: 0.85,
        max_tokens: 1000,
      }),
      signal: AbortSignal.timeout(30000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    return data.choices?.[0]?.message?.content ?? null;
  } catch {
    return null;
  }
}

async function callOpenRouterVision(messages: any[], imageUrl: string): Promise<string | null> {
  if (!OPENROUTER_KEY) return null;
  try {
    const lastMsg = messages[messages.length - 1];
    const visionMessages = messages.slice(0, -1);
    visionMessages.push({
      role: "user",
      content: [
        { type: "text", text: lastMsg?.content || "Décris cette image." },
        { type: "image_url", image_url: { url: imageUrl, detail: "auto" } },
      ],
    });

    const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENROUTER_KEY}`,
        "HTTP-Referer": "https://arteia.app",
        "X-Title": "Arteia Muse Vision",
      },
      body: JSON.stringify({
        model: "meta-llama/llama-3.2-90b-vision-preview",
        messages: visionMessages,
        temperature: 0.85,
        max_tokens: 1000,
      }),
      signal: AbortSignal.timeout(30000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    return data.choices?.[0]?.message?.content ?? null;
  } catch {
    return null;
  }
}

async function callSupabaseEdge(messages: any[], sessionToken?: string): Promise<string | null> {
  try {
    const headers: Record<string, string> = { "Content-Type": "application/json" };
    if (sessionToken) headers["Authorization"] = `Bearer ${sessionToken}`;
    const res = await fetch(SUPABASE_FUNCTION_URL, {
      method: "POST",
      headers,
      body: JSON.stringify({ messages }),
      signal: AbortSignal.timeout(10000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    return data.reply ?? null;
  } catch {
    return null;
  }
}

function detectCreativeIntent(message: string): string | null {
  const intents: Record<string, string[]> = {
    ideas: ["idée", "inspire", "inspiration", "suggest", "propose", "concept", "thème", "sujet"],
    style: ["style", "analyse", "technique", "mouvement", "genre", "approche", "méthode"],
    critique: ["critique", "commente", "évalue", "note", "feedback", "avis", "améliore", "amélioration"],
    describe: ["décris", "décrit", "describe", "visualise", "représente", "illustre"],
  };

  for (const [tool, keywords] of Object.entries(intents)) {
    if (keywords.some((k) => message.includes(k))) {
      return tool;
    }
  }
  return null;
}

function localFallback(message: string): string {
  const m = message.toLowerCase();
  if (m.includes("idée") || m.includes("inspire")) {
    const ideas = [
      "Et si tu faisais un autoportrait… mais uniquement avec des formes géométriques ?",
      "4 accords, un lever de soleil en tête. Commence en mineur, termine en majeur.",
      "Un micro-poème de 6 mots sur la première fois que tu as créé quelque chose qui t'a surpris.",
      "Dessine ton état d'esprit actuel sous forme de paysage imaginaire.",
    ];
    return ideas[Math.abs(message.split("").reduce((a, b) => a + b.charCodeAt(0), 0)) % ideas.length];
  }
  if (m.includes("bonjour") || m.includes("salut")) return "Hé ! Ravie de te retrouver ✨";
  if (m.includes("merci")) return "Avec plaisir !";
  return "Je comprends. Peux-tu me donner plus de détails ? Je suis là pour t'aider avec tes projets créatifs 🎨";
}

app.post("/api/muse/chat", async (req, res) => {
  try {
    const { message, imageUrl, history = [], contentType = "general", userId } = req.body;

    if (!message && !imageUrl) {
      return res.json({ reply: "" });
    }

    console.log("[MuseAPI] message:", message?.slice(0, 60), "image:", !!imageUrl, "userId:", userId);

    const lower = (message || "").toLowerCase();
    const wordCount = (message || "").split(" ").filter((w) => w).length;

    const needsWeb = /(nouvelle|actualité|dernier|news|info|aujourd'hui|202[4-9]|qui est|qu'est-ce que|c'est quoi|définition|histoire de|origine|population|capitale|président|découverte|invention|météo|heure|date|latest|current|who is|what is|definition|history of|capital of|president of|population of|weather|time in|recherche|cherche|google|internet)/i.test(message || "");
    const isQuestion = /(\?|qui|quoi|comment|pourquoi|quand|où|combien|what|when|where|how|why|who|which)/i.test(message || "");

    const webResults = (needsWeb || isQuestion) ? await searchWeb(message || "") : null;
    const systemPrompt = buildSystemPrompt(webResults || "");

    const apiMessages: any[] = [{ role: "system", content: systemPrompt }];

    // Contexte conversationnel : analyser les messages précédents pour personnaliser
    const recentContext = history.slice(-6).map((m: any) => ({
      role: m.role === "assistant" ? "assistant" : "user",
      content: m.content || "",
    }));

    // Détecter si l'utilisateur demande un outil créatif
    const creativeIntent = detectCreativeIntent(lower);
    if (creativeIntent && !imageUrl) {
      const creativeSystem = `Tu es Arteïa Muse, une IA créative pour artistes. L'utilisateur demande un outil créatif spécifique : ${creativeIntent}. Réponds de manière adaptée à cet outil.`;
      apiMessages[0].content = creativeSystem + "\n" + systemPrompt;
    }

    for (const msg of recentContext) {
      apiMessages.push(msg);
    }

    if (imageUrl) {
      apiMessages.push({
        role: "user",
        content: [
          { type: "text", text: message || "Décris cette image." },
          { type: "image_url", image_url: { url: imageUrl, detail: "auto" } },
        ],
      });
    } else {
      apiMessages.push({ role: "user", content: message });
    }

    let reply: string | null = null;

    if (imageUrl) {
      reply = await callOpenRouterVision(apiMessages, imageUrl);
    }
    if (!reply && GROQ_KEY) {
      reply = await callGroq(apiMessages);
    }
    if (!reply && OPENROUTER_KEY) {
      reply = await callOpenRouter(apiMessages, "meta-llama/llama-3.1-8b-instruct");
    }
    if (!reply) {
      const sessionToken = req.headers.authorization?.replace("Bearer ", "");
      reply = await callSupabaseEdge(apiMessages, sessionToken);
    }
    if (!reply) {
      reply = localFallback(message || "");
    }

    res.json({ reply });
  } catch (error) {
    console.error("[MuseAPI] Error:", error);
    res.json({ reply: "Désolé, une erreur est survenue. Réessaie dans un instant. 🌙" });
  }
});

app.post("/api/muse/creative", async (req, res) => {
  try {
    const { tool, prompt, imageUrl } = req.body;

    if (!tool && !prompt && !imageUrl) {
      return res.json({ result: "Précise un outil créatif : ideas, style, critique, ou describe." });
    }

    const systemPrompt = `Tu es Arteïa Muse, une IA créative pour artistes. Tu parles français avec un style poétique et visuel. Tu réponds de manière concise et inspirante. Tu es un expert en arts visuels, musique, écriture, animation, et design.`;

    let userMessage = "";
    switch (tool) {
      case "ideas":
        userMessage = `Génère 5 idées créatives originales liées à ce sujet : ${prompt || "l'art contemporain"}. Pour chaque idée, donne un titre et une description en 1-2 phrases. Utilise des métaphores visuelles.`;
        break;
      case "style":
        userMessage = `Analyse le style artistique de cette description : ${prompt || ""}. Identifie les mouvements, techniques, couleurs, et émotions dominantes. Propose 3 variations stylistiques.`;
        break;
      case "critique":
        userMessage = `Fais une critique constructive et bienveillante de cette œuvre : ${prompt || ""}. Mentionne les forces, les axes d'amélioration, et une suggestion concrète. Style : diplomate artistique.`;
        break;
      case "describe":
        userMessage = `Décris cette image de manière poétique et visuelle en 2-3 phrases. Utilise des métaphores artistiques. Décris les couleurs, textures, lumières, émotions.`;
        break;
      default:
        userMessage = prompt || "Parle-moi d'art.";
    }

    const messages = [
      { role: "system", content: systemPrompt },
      { role: "user", content: imageUrl ? [{ type: "text", text: userMessage }, { type: "image_url", image_url: { url: imageUrl, detail: "auto" } }] : userMessage },
    ];

    let result: string | null = null;

    if (imageUrl) {
      result = await callOpenRouterVision(messages, imageUrl);
    }
    if (!result && GROQ_KEY) {
      result = await callGroq(messages);
    }
    if (!result && OPENROUTER_KEY) {
      result = await callOpenRouter(messages, "meta-llama/llama-3.1-8b-instruct");
    }
    if (!result) {
      result = localFallback(prompt || "");
    }

    res.json({ result });
  } catch (error) {
    console.error("[MuseAPI] Creative error:", error);
    res.json({ result: "Une erreur est survenue. Réessaie. 🌙" });
  }
});

app.post("/api/muse/generate", async (req, res) => {
  try {
    const { prompt, style = "digital art", size = "1024x1024" } = req.body;

    if (!prompt) {
      return res.json({ error: "Un prompt est requis pour générer." });
    }

    const sizeMap: Record<string, string> = {
      "256x256": "256x256",
      "512x512": "512x512",
      "1024x1024": "1024x1024",
      "1792x1024": "1792x1024",
      "1024x1792": "1024x1792",
    };
    const resolvedSize = sizeMap[size] || "1024x1024";

    let imageUrl: string | null = null;

    // Essayer OpenRouter avec un modèle de génération d'image si disponible
    if (OPENROUTER_KEY) {
      try {
        const model = "stabilityai/stable-diffusion-xl-base-1.0";
        const genRes = await fetch("https://openrouter.ai/api/v1/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${OPENROUTER_KEY}`,
            "HTTP-Referer": "https://arteia.app",
            "X-Title": "Arteia Muse Generate",
          },
          body: JSON.stringify({
            model,
            messages: [
              { role: "system", content: "Tu es un générateur d'images artistiques. Réponds uniquement avec une description d'image détaillée en français." },
              { role: "user", content: `Génère une image artistique de : ${prompt}. Style : ${style}.` },
            ],
            extra_body: {
              image_model: model,
            },
          }),
          signal: AbortSignal.timeout(30000),
        });
        if (genRes.ok) {
          const genData = await genRes.json();
          imageUrl = genData.choices?.[0]?.message?.content || null;
        }
      } catch {
        // Image generation not available via OpenRouter for this model
      }
    }

    // Fallback : retourner une description d'image détaillée que l'utilisateur peut utiliser
    if (!imageUrl) {
      const description = `Image générée : ${prompt} en style ${style}. Une œuvre d'art numérique avec des détails riches, des couleurs vibrantes et une composition soignée.`;
      imageUrl = description;
    }

    res.json({ imageUrl, prompt, style });
  } catch (error) {
    console.error("[MuseAPI] Generate error:", error);
    res.json({ error: "La génération a échoué. Réessaie. 🎨" });
  }
});

app.get("/api/muse/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ==================== GÉNÉRATION DE FICHIERS ====================

import { PDFDocument, StandardFonts, rgb } from "pdf-lib";
import { Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell, WidthType } from "docx";
import * as XLSX from "xlsx";
import { execFile } from "child_process";
import { promisify } from "util";
import { tmpdir } from "os";
import { join } from "path";
import { writeFileSync, unlinkSync, readFileSync } from "fs";

const execFileAsync = promisify(execFile);

async function generatePDF(content: string, title: string): Promise<Buffer> {
  const pdfDoc = await PDFDocument.create();
  const page = pdfDoc.addPage([612, 792]);
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  const lines = content.split("\n");
  let y = 50;

  const titleWidth = font.widthOfTextAtSize(title, 24);
  page.drawText(title, { x: 50, y: 750, size: 24, font: boldFont, color: rgb(0.1, 0.1, 0.4) });
  y = 720;

  for (const line of lines) {
    if (y < 50) break;
    const trimmed = line.trim();
    if (trimmed.startsWith("# ")) {
      page.drawText(trimmed.slice(2), { x: 50, y, size: 16, font: boldFont, color: rgb(0.1, 0.1, 0.4) });
      y -= 24;
    } else if (trimmed.startsWith("## ")) {
      page.drawText(trimmed.slice(3), { x: 50, y, size: 13, font: boldFont, color: rgb(0.2, 0.2, 0.5) });
      y -= 20;
    } else if (trimmed.startsWith("- ")) {
      page.drawText("• " + trimmed.slice(2), { x: 70, y, size: 10, font, color: rgb(0.15, 0.15, 0.15) });
      y -= 16;
    } else if (trimmed === "") {
      y -= 10;
    } else {
      page.drawText(trimmed, { x: 50, y, size: 10, font, color: rgb(0.15, 0.15, 0.15) });
      y -= 16;
    }
  }

  return await pdfDoc.save();
}

async function generateWord(content: string, title: string): Promise<Buffer> {
  const doc = new Document({
    sections: [{
      properties: {},
      children: [
        new Paragraph({
          text: title,
          heading: HeadingLevel.HEADING_1,
          children: [new TextRun({ bold: true, size: 32 })],
        }),
        ...content.split("\n").filter(l => l.trim()).map(line => {
          const trimmed = line.trim();
          if (trimmed.startsWith("# ")) {
            return new Paragraph({ text: trimmed.slice(2), heading: HeadingLevel.HEADING_2 });
          }
          if (trimmed.startsWith("## ")) {
            return new Paragraph({ text: trimmed.slice(3), heading: HeadingLevel.HEADING_3 });
          }
          if (trimmed.startsWith("- ")) {
            return new Paragraph({ text: trimmed.slice(2), bullet: true });
          }
          return new Paragraph({ text: trimmed });
        }),
      ],
    }],
  });

  return await Packer.toBuffer(doc);
}

async function generateExcel(data: Record<string, string[]>[], title: string): Promise<Buffer> {
  const wb = XLSX.utils.book_new();
  const wsData = [[title]];

  for (const sheet of data) {
    wsData.push([]);
    wsData.push([sheet.name || "Sheet"]);
    if (sheet.headers) {
      wsData.push(sheet.headers);
    }
    if (sheet.rows) {
      for (const row of sheet.rows) {
        wsData.push(row);
      }
    }
  }

  const ws = XLSX.utils.aoa_to_sheet(wsData);
  XLSX.utils.book_append_sheet(wb, ws, title);
  return XLSX.write(wb, { type: "buffer", bookType: "xlsx" });
}

async function generateVideo(prompt: string): Promise<Buffer> {
  const tmpDir = tmpdir();
  const inputFile = join(tmpDir, `muse_input_${Date.now()}.txt`);
  const outputFile = join(tmpDir, `muse_video_${Date.now()}.mp4`);

  writeFileSync(inputFile, prompt);

  try {
    await execFileAsync("ffmpeg", [
      "-f", "lavfi",
      "-i", `color=c=0x1a1a2e:s=1280x720:d=5,drawtext=text='${prompt.replace(/'/g, "\\'")}':fontsize=24:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2`,
      "-c:v", "libx264",
      "-pix_fmt", "yuv420p",
      "-t", "5",
      outputFile,
    ]);

    const buffer = readFileSync(outputFile);
    unlinkSync(inputFile);
    unlinkSync(outputFile);
    return buffer;
  } catch {
    unlinkSync(inputFile);
    throw new Error("Video generation failed");
  }
}

app.post("/api/muse/generate/pdf", async (req, res) => {
  try {
    const { content, title = "Document Muse" } = req.body;
    if (!content) return res.status(400).json({ error: "Content requis" });

    const buffer = await generatePDF(content, title);
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="${title}.pdf"`);
    res.send(buffer);
  } catch (error) {
    console.error("[MuseAPI] PDF error:", error);
    res.status(500).json({ error: "Erreur génération PDF" });
  }
});

app.post("/api/muse/generate/word", async (req, res) => {
  try {
    const { content, title = "Document Muse" } = req.body;
    if (!content) return res.status(400).json({ error: "Content requis" });

    const buffer = await generateWord(content, title);
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
    res.setHeader("Content-Disposition", `attachment; filename="${title}.docx"`);
    res.send(buffer);
  } catch (error) {
    console.error("[MuseAPI] Word error:", error);
    res.status(500).json({ error: "Erreur génération Word" });
  }
});

app.post("/api/muse/generate/excel", async (req, res) => {
  try {
    const { data, title = "Feuille Muse" } = req.body;
    if (!data) return res.status(400).json({ error: "Data requise" });

    const buffer = await generateExcel(data, title);
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", `attachment; filename="${title}.xlsx"`);
    res.send(buffer);
  } catch (error) {
    console.error("[MuseAPI] Excel error:", error);
    res.status(500).json({ error: "Erreur génération Excel" });
  }
});

app.post("/api/muse/generate/video", async (req, res) => {
  try {
    const { prompt, title = "Video Muse" } = req.body;
    if (!prompt) return res.status(400).json({ error: "Prompt requis" });

    const buffer = await generateVideo(prompt);
    res.setHeader("Content-Type", "video/mp4");
    res.setHeader("Content-Disposition", `attachment; filename="${title}.mp4"`);
    res.send(buffer);
  } catch (error) {
    console.error("[MuseAPI] Video error:", error);
    res.status(500).json({ error: "Erreur génération vidéo" });
  }
});

const PORT = process.env.MUSE_SERVER_PORT || 3100;
app.listen(PORT, () => {
  console.log(`[MuseAPI] Server running on port ${PORT}`);
  console.log(`[MuseAPI] Groq: ${GROQ_KEY ? "configured" : "missing"}`);
  console.log(`[MuseAPI] OpenRouter: ${OPENROUTER_KEY ? "configured" : "missing"}`);
});