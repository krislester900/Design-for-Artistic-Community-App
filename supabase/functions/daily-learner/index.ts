import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Parser from "https://esm.sh/rss-parser@3.13.0";

const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";

const RSS_FEEDS: Array<{ url: string; name: string; category: string; language: string }> = [
  // Anglais
  { url: "https://www.thisiscolossal.com/feed/", name: "Colossal", category: "visual", language: "en" },
  { url: "https://www.creativeboom.com/feed/", name: "Creative Boom", category: "visual", language: "en" },
  { url: "https://booooooom.com/feed/", name: "Booooooom", category: "visual", language: "en" },
  { url: "https://linesandcolors.com/feed/", name: "Lines and Colors", category: "technique", language: "en" },
  { url: "https://www.openculture.com/category/art/feed", name: "Open Culture Art", category: "general", language: "en" },
  { url: "https://www.poetryfoundation.org/feeds/poetrymagazine", name: "Poetry Magazine", category: "writing", language: "en" },
  { url: "https://www.guitarworld.com/feed", name: "Guitar World", category: "music", language: "en" },
  { url: "https://www.artnews.com/feed/", name: "ARTnews", category: "visual", language: "en" },
  // Français
  { url: "https://www.9emeart.fr/feed", name: "9ème Art", category: "comics", language: "fr" },
  { url: "https://www.actusf.com/spip.php?page=backend", name: "ActuSF", category: "writing", language: "fr" },
  { url: "https://www.bubblebd.com/feed/", name: "Bubble BD", category: "comics", language: "fr" },
  { url: "https://www.koreus.com/feed/", name: "Koreus Art", category: "visual", language: "fr" },
  { url: "https://www.designspiration.com/feed/", name: "Designspiration", category: "visual", language: "en" },
  { url: "https://www.ignant.com/feed/", name: "Ignant", category: "visual", language: "en" },
  // Technique
  { url: "https://www.cloudinary.com/blog/feed", name: "Cloudinary Blog", category: "technique", language: "en" },
  { url: "https://css-art.com/feed/", name: "CSS Art", category: "technique", language: "en" },
];

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "POST", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }

  try {
    const auth = req.headers.get("authorization")?.replace("Bearer ", "");
    const cronHeader = req.headers.get("x-cron-secret") ?? "";
    if (auth !== CRON_SECRET && cronHeader !== CRON_SECRET) {
      return new Response(JSON.stringify({ error: "Non autorisé" }), { status: 403, headers: { "Content-Type": "application/json" } });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);
    const groqKey = Deno.env.get("GROQ_API_KEY");

    const results: string[] = [];

    // === PARTIE 1 : RSS ===
    const selectedFeeds = RSS_FEEDS.sort(() => Math.random() - 0.5).slice(0, 3);

    for (const feed of selectedFeeds) {
      try {
        const parser = new Parser();
        const parsed = await parser.parseURL(feed.url);

        if (!parsed.items || parsed.items.length === 0) {
          results.push(`⚠️ ${feed.name}: aucun article trouvé`);
          continue;
        }

        const articles = parsed.items.slice(0, 3);
        let added = 0;

        for (const article of articles) {
          const title = article.title?.trim() ?? "";
          const content = article.contentSnippet ?? article.content ?? "";
          const link = article.link ?? "";

          if (!title || !content || content.length < 50) continue;

          const { data: existing } = await supabase
            .from("ai_knowledge_base")
            .select("id")
            .ilike("title", `%${title.substring(0, 50)}%`)
            .limit(1);

          if (existing && existing.length > 0) {
            results.push(`⏭️ ${feed.name}: déjà existant`);
            continue;
          }

          let knowledgeArticle: { category: string; title: string; content: string; tags: string[] } | null = null;

          if (groqKey) {
            try {
              knowledgeArticle = await summarizeWithGroq(groqKey, title, content, feed.category, feed.language);
            } catch {
              knowledgeArticle = fallbackTransform(title, content, feed.category);
            }
          } else {
            knowledgeArticle = fallbackTransform(title, content, feed.category);
          }

          if (!knowledgeArticle) continue;

          const { error: insertError } = await supabase.from("ai_knowledge_base").insert({
            category: knowledgeArticle.category,
            title: knowledgeArticle.title,
            content: knowledgeArticle.content,
            tags: knowledgeArticle.tags,
            source: `web:rss:${feed.name}`,
            source_url: link,
            source_updated_at: new Date().toISOString(),
          });

          if (insertError) {
            results.push(`❌ ${feed.name}: erreur insertion - ${insertError.message}`);
          } else {
            added++;
            results.push(`✅ ${feed.name}: ajouté "${knowledgeArticle.title}"`);
          }
        }

        await supabase.from("ai_web_sources").upsert(
          { url: feed.url, name: feed.name, category: feed.category, language: feed.language, last_fetched_at: new Date().toISOString(), articles_added: added, last_error: null },
          { onConflict: "url" }
        );
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : String(err);
        results.push(`❌ ${feed.name}: erreur - ${errMsg}`);
        await supabase.from("ai_web_sources").upsert(
          { url: feed.url, name: feed.name, category: feed.category, language: feed.language, last_error: errMsg },
          { onConflict: "url" }
        );
      }
    }

    // === PARTIE 2 : Synthèse depuis conversations utilisateur ===
    if (groqKey) {
      try {
        const synthResult = await synthesizeFromConversations(supabase, groqKey);
        results.push(...synthResult);
      } catch (e) {
        results.push(`⚠️ Synthèse conversations: ${e instanceof Error ? e.message : String(e)}`);
      }
    }

    return new Response(JSON.stringify({ ok: true, results }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

async function summarizeWithGroq(apiKey: string, title: string, content: string, defaultCategory: string, language: string): Promise<{ category: string; title: string; content: string; tags: string[] } | null> {
  const langInstruction = language === "fr"
    ? "Garde l'article en français si possible. Génère la fiche en français."
    : "Translate to French if needed. Generate the knowledge card in French.";

  const prompt = `Tu es un expert artistique qui transforme des articles web en fiches de connaissance.

Titre original : "${title}"
Contenu : ${content.substring(0, 3000)}
Langue source : ${language}

${langInstruction}

Génère une fiche de connaissance avec :
1. Un TITRE clair et concis en français
2. Un CONTENU structuré : points clés, techniques, conseils pratiques (maximum 200 mots)
3. Une CATÉGORIE parmi : visual, music, writing, comics, technique, general
4. Des TAGS (3-5 mots-clés en français)

Format JSON uniquement :
{"title": "...", "content": "...", "category": "...", "tags": ["...", "..."]}`;

  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({
      model: "llama3-70b-8192",
      messages: [{ role: "user", content: prompt }],
      max_tokens: 1024,
      temperature: 0.5,
    }),
  });

  if (!response.ok) return null;

  const data = await response.json();
  const raw = data.choices?.[0]?.message?.content ?? "";
  if (!raw) return null;

  try {
    const parsed = JSON.parse(raw);
    return {
      title: parsed.title || title,
      content: parsed.content || content.substring(0, 2000),
      category: ["visual", "music", "writing", "comics", "technique", "general"].includes(parsed.category) ? parsed.category : defaultCategory,
      tags: Array.isArray(parsed.tags) ? parsed.tags.slice(0, 5) : [defaultCategory],
    };
  } catch {
    return {
      title: `Article: ${title.substring(0, 100)}`,
      content: `Résumé d'article :\n\n${content.substring(0, 2000)}`,
      category: defaultCategory,
      tags: [defaultCategory],
    };
  }
}

function fallbackTransform(title: string, content: string, category: string): { category: string; title: string; content: string; tags: string[] } {
  return {
    title: `Article: ${title.substring(0, 100)}`,
    content: `Source web :\n\n${content.substring(0, 2000)}`,
    category,
    tags: [category],
  };
}

async function synthesizeFromConversations(supabase: any, groqKey: string): Promise<string[]> {
  const results: string[] = [];

  // Récupérer les paires Q/A approuvées des 7 derniers jours
  const { data: recentPairs } = await supabase
    .from("ai_training_data")
    .select("question, answer, category")
    .gte("created_at", new Date(Date.now() - 7 * 86400000).toISOString())
    .limit(15);

  if (!recentPairs || recentPairs.length < 3) {
    results.push(`⏭️ Synthèse: pas assez de données (${recentPairs?.length ?? 0} paires trouvées, minimum 3)`);
    return results;
  }

  // Grouper par catégorie
  const byCategory: Record<string, { questions: string[]; answers: string[] }> = {};
  for (const pair of recentPairs) {
    const cat = pair.category || "general";
    if (!byCategory[cat]) byCategory[cat] = { questions: [], answers: [] };
    byCategory[cat].questions.push(pair.question);
    byCategory[cat].answers.push(pair.answer);
  }

  for (const [category, data] of Object.entries(byCategory)) {
    if (data.questions.length < 2) continue;

    // Vérifier si un article similaire existe déjà
    const sampleQuestion = data.questions[0].substring(0, 60);
    const { data: existing } = await supabase
      .from("ai_knowledge_base")
      .select("id")
      .ilike("title", `%${sampleQuestion.substring(0, 40)}%`)
      .limit(1);

    if (existing && existing.length > 0) {
      results.push(`⏭️ Synthèse ${category}: article similaire existe déjà`);
      continue;
    }

    const prompt = `Tu es un expert artistique. À partir de questions d'utilisateurs et de leurs réponses, crée une fiche de connaissance utile.

Questions posées :
${data.questions.map((q, i) => `${i + 1}. ${q}`).join("\n")}

Réponses données :
${data.answers.map((a, i) => `${i + 1}. ${a.substring(0, 300)}`).join("\n")}

Génère une fiche de connaissance synthétique en français qui répond au besoin commun derrière ces questions.
Format JSON :
{"title": "...", "content": "...", "tags": ["tag1", "tag2", "tag3"]}
Le contenu doit être pratique, structuré (points clés, conseils). Maximum 200 mots.`;

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${groqKey}` },
      body: JSON.stringify({
        model: "llama3-70b-8192",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 1024,
        temperature: 0.5,
      }),
    });

    if (!response.ok) continue;

    const raw = (await response.json()).choices?.[0]?.message?.content ?? "";
    if (!raw) continue;

    try {
      const parsed = JSON.parse(raw);
      await supabase.from("ai_knowledge_base").insert({
        category,
        title: parsed.title || `FAQ: ${sampleQuestion}`,
        content: parsed.content,
        tags: Array.isArray(parsed.tags) ? parsed.tags.slice(0, 5) : [category],
        source: "synthesis:conversations",
      });
      results.push(`✅ Synthèse ${category}: ajouté "${parsed.title}"`);
    } catch {
      results.push(`⚠️ Synthèse ${category}: erreur parsing JSON`);
    }
  }

  return results;
}
