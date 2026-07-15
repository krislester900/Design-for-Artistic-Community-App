import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TARGET_PER_STYLE = 500;
const CONCURRENT_BOARDS = 5;
const REPLICATE_API_KEY = Deno.env.get("REPLICATE_API_KEY") ?? "";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "POST", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }

  try {
    const auth = req.headers.get("authorization")?.replace("Bearer ", "");
    const cronHeader = req.headers.get("x-cron-secret") ?? "";
    const cronSecret = Deno.env.get("CRON_SECRET") ?? "";
    // Fail-closed : si CRON_SECRET n'est pas configuré OU si le secret ne correspond pas, on refuse.
    if (!cronSecret || (auth !== cronSecret && cronHeader !== cronSecret)) {
      return new Response(JSON.stringify({ error: "Non autorisé" }), { status: 403, headers: { "Content-Type": "application/json" } });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: boards } = await supabase
      .from("ai_pinterest_sources")
      .select("*, ai_manga_styles!inner(slug, name, training_status, reference_count, prompt_template, model_version, model_owner, model_name)")
      .eq("is_active", true);

    if (!boards || boards.length === 0) {
      return new Response(JSON.stringify({ ok: true, message: "Aucun board configuré" }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const stylesToTrain = new Set<string>();
    const allResults: string[] = [];

    const processBoard = async (board: any): Promise<string> => {
      const username = board.username;
      const boardName = board.board_name;
      const styleSlug = board.style_slug;
      const styleId = board.style_id;
      const styleName = board.ai_manga_styles?.name ?? styleSlug;
      const currentTotal = board.total_collected ?? 0;
      const styleMeta = board.ai_manga_styles ?? {};
      const needed = TARGET_PER_STYLE - currentTotal;

      if (currentTotal >= TARGET_PER_STYLE) {
        return `⏭️ ${username}/${boardName}: déjà ${currentTotal}/${TARGET_PER_STYLE} images`;
      }

      try {
        // Parallelise les 4 sources en même temps
        const [rssUrls, pinterestUrls, bingUrls, googleUrls] = await Promise.all([
          fetchRss(username, boardName).catch(() => [] as string[]),
          fetchPinterestHtml(username, boardName).catch(() => [] as string[]),
          fetchBingImages(styleName).catch(() => [] as string[]),
          fetchGoogleImages(styleName, username).catch(() => [] as string[]),
        ]);

        let allNewUrls = [...rssUrls, ...pinterestUrls, ...bingUrls, ...googleUrls];

        // Bootstrap Replicate si pas assez d'images
        if (allNewUrls.length < 50 && needed > 50 && REPLICATE_API_KEY && styleMeta.prompt_template) {
          try {
            const bootUrls = await generateBootstrapImages(supabase, styleId, styleSlug, styleMeta, needed);
            allNewUrls = allNewUrls.concat(bootUrls);
            if (bootUrls.length > 0) {
              allResults.push(`🎨 Bootstrap Replicate: ${bootUrls.length} images pour "${styleName}"`);
            }
          } catch (e) {
            allResults.push(`⚠️ Bootstrap Replicate échoué ${styleName}: ${e instanceof Error ? e.message : String(e)}`);
          }
        }

        const uniqueUrls = [...new Set(allNewUrls)];
        if (uniqueUrls.length === 0) {
          return `⚠️ ${username}/${boardName}: aucune image trouvée`;
        }

        // Déduplication batch
        const existingUrls = new Set<string>();
        for (let i = 0; i < uniqueUrls.length; i += 50) {
          const chunk = uniqueUrls.slice(i, i + 50);
          const { data: existing } = await supabase
            .from("ai_manga_references")
            .select("image_url")
            .in("image_url", chunk)
            .limit(50);
          if (existing) for (const row of existing) existingUrls.add(row.image_url);
        }

        const newUrls = uniqueUrls.filter(u => !existingUrls.has(u)).slice(0, needed);

        if (newUrls.length === 0) {
          return `⏭️ ${username}/${boardName}: 0 nouvelle (total: ${currentTotal}/${TARGET_PER_STYLE})`;
        }

        // Batch insert
        const { error: insertErr } = await supabase.from("ai_manga_references").insert(
          newUrls.map(url => ({
            style_id: styleId,
            image_url: url,
            source: url.includes("replicate") ? "generated" : "scrape",
            caption: "",
          }))
        );

        if (insertErr) return `❌ ${username}/${boardName}: échec insert - ${insertErr.message}`;

        const total = currentTotal + newUrls.length;
        await Promise.all([
          supabase.from("ai_pinterest_sources").update({
            last_fetched_at: new Date().toISOString(),
            total_collected: total,
            last_error: null,
          }).eq("id", board.id),
          supabase.from("ai_manga_styles").update({ reference_count: total }).eq("id", styleId),
        ]);

        if (total >= 200) stylesToTrain.add(styleSlug);

        return `✅ ${username}/${boardName}: ${newUrls.length} nouvelles (total: ${total}/${TARGET_PER_STYLE})`;
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        await supabase.from("ai_pinterest_sources").update({ last_error: msg }).eq("id", board.id);
        return `❌ ${username}/${boardName}: ${msg}`;
      }
    };

    // Parallelise les boards avec contrôle de concurrence
    for (let i = 0; i < boards.length; i += CONCURRENT_BOARDS) {
      const batch = boards.slice(i, i + CONCURRENT_BOARDS);
      const batchResults = await Promise.all(batch.map(processBoard));
      allResults.push(...batchResults);
    }

    // Auto-training pour les styles prêts
    await Promise.all(Array.from(stylesToTrain).map(async (slug) => {
      try {
        await fetch(`${supabaseUrl}/functions/v1/manga-trainer`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${cronSecret}` },
          body: JSON.stringify({ action: "start_training", style_slug: slug }),
        });
        allResults.push(`🚀 Entraînement auto déclenché pour ${slug}`);
      } catch {
        allResults.push(`⚠️ Échec auto-training pour ${slug}`);
      }
    }));

    const totalPins = allResults.reduce((sum, r) => {
      const m = r.match(/^✅.*?(\d+) nouvelles/);
      return sum + (m ? parseInt(m[1]) : 0);
    }, 0);

    return new Response(JSON.stringify({ ok: true, results: allResults, pins_collected: totalPins, styles_ready: Array.from(stylesToTrain) }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error("pinterest-collector error:", msg);
    return new Response(JSON.stringify({ error: "Erreur interne" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

// ---------- Fetch sources (tous parallélisés) ----------

async function fetchRss(username: string, boardName: string): Promise<string[]> {
  const rssUrl = `https://www.pinterest.com/${username}/${boardName}.rss`;
  const resp = await fetch(rssUrl, {
    headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" },
  });
  if (!resp.ok) return [];
  const xml = await resp.text();
  const urls = new Set<string>();
  const imgPattern = /<img[^>]+src="(https?:\/\/i\.pinimg\.com\/[^"]+\.(?:jpg|png|webp))"/g;
  let m;
  while ((m = imgPattern.exec(xml)) !== null) urls.add(m[1]);
  if (urls.size > 0) return Array.from(urls);
  const mediaPattern = /<media:content[^>]+url="(https?:\/\/[^"]+\.(?:jpg|png|webp))"/g;
  while ((m = mediaPattern.exec(xml)) !== null) urls.add(m[1]);
  return Array.from(urls);
}

async function fetchPinterestHtml(username: string, boardName: string): Promise<string[]> {
  const resp = await fetch(`https://www.pinterest.com/${username}/${boardName}/`, {
    headers: {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      "Accept": "text/html,application/xhtml+xml",
      "Accept-Language": "en-US,en;q=0.9",
    },
  });
  if (!resp.ok) return [];
  const html = await resp.text();
  const urls = new Set<string>();
  const patterns = [
    /https:\/\/i\.pinimg\.com\/(?:originals|[0-9]+x)\/[a-zA-Z0-9]+\/[a-zA-Z0-9]+\/[a-zA-Z0-9]+\.(?:jpg|png|webp)/g,
    /"image_original_url":"([^"]+\.(?:jpg|png|webp))"/g,
    /"url":"([^"]+\.(?:jpg|png|webp)[^"]*)"/g,
  ];
  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(html)) !== null) {
      const u = match[1] ?? match[0];
      urls.add(u.replace(/\/[0-9]+x\//, "/originals/").replace(/\\u0026/g, "&"));
    }
  }
  return Array.from(urls);
}

async function fetchBingImages(styleName: string): Promise<string[]> {
  const resp = await fetch(
    `https://www.bing.com/images/search?q=${encodeURIComponent(`${styleName} manga anime artwork art`)}&count=50`,
    { headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", "Accept": "text/html" } },
  );
  if (!resp.ok) return [];
  const html = await resp.text();
  const urls = new Set<string>();
  const patterns = [
    /"m":{"[^}]*"src":"(https?:\/\/[^"]+\.(?:jpg|png|webp))"/g,
    /<img[^>]+src="(https?:\/\/[^"]+\.(?:jpg|png|webp)[^"]*?)"/g,
    /mediaUrl":"(https?:\/\/[^"]+\.(?:jpg|png|webp))"/g,
    /"contentUrl":"(https?:\/\/[^"]+\.(?:jpg|png|webp))"/g,
  ];
  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(html)) !== null) {
      const u = match[1].replace(/\\\//g, "/").split("?")[0].split("&")[0];
      if (u.startsWith("http") && !u.includes("bing.com") && !u.includes("th.bing.com")) urls.add(u);
    }
  }
  const thumbPattern = /https?:\/\/th\.bing\.com\/th\/id\/([^"&\s]+)/g;
  let tm;
  while ((tm = thumbPattern.exec(html)) !== null) urls.add(`https://i.bing.com/th/id/${tm[1]}`);
  return Array.from(urls);
}

async function fetchGoogleImages(styleName: string, username: string): Promise<string[]> {
  const resp = await fetch(
    `https://www.google.com/search?tbm=isch&q=${encodeURIComponent(`${styleName} manga ${username}`)}&tbs=isz:l`,
    { headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", "Accept": "text/html" } },
  );
  if (!resp.ok) return [];
  const html = await resp.text();
  const urls = new Set<string>();
  const patterns = [
    /"(https?:\/\/[^"]+\.(?:jpg|png|webp)[^"]*)"/g,
    /\["(https?:\/\/[^"]+\.(?:jpg|png|webp)[^"]*)"/g,
    /"ou":"([^"]+\.(?:jpg|png|webp))"/g,
  ];
  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(html)) !== null) {
      const u = match[1].replace(/\\u003d/g, "=").replace(/\\u0026/g, "&").split("?")[0].split("&")[0];
      if (u.startsWith("http") && !u.includes("google") && !u.includes("gstatic.com")) urls.add(u);
    }
  }
  return Array.from(urls);
}

// ---------- Bootstrap Replicate ----------

async function generateBootstrapImages(
  supabase: any, styleId: number, styleSlug: string,
  styleMeta: any, needed: number,
): Promise<string[]> {
  const owner = styleMeta.model_owner ?? "rocketdigitalai";
  const model = styleMeta.model_name ?? "animagine-xl-4.0";
  const version = styleMeta.model_version ?? "7af46ee494f1cf196d49a8592737f4eb789e34a5a995751b23a869d19f5dc2ba";
  const promptTemplate = styleMeta.prompt_template ?? "manga style, {scene}";
  const negPrompt = styleMeta.negative_prompt ?? "";
  const width = styleMeta.width ?? 1024;
  const height = styleMeta.height ?? 1024;
  const steps = styleMeta.num_inference_steps ?? 25;
  const guidance = styleMeta.guidance_scale ?? 6.0;

  // Generate diverse scenes to bootstrap the reference set
  const scenes = [
    "character portrait, detailed face, intense expression",
    "dynamic action scene, mid-punch, motion lines",
    "two characters fighting, clash, impact sparks",
    "landscape with character, dramatic sky, wide shot",
    "character close-up, emotional moment, tears",
    "group of characters, team pose, determination",
    "villain reveal, menacing stance, dark aura",
    "speed lines, running character, dynamic perspective",
  ];

  const generated: string[] = [];
  const batchSize = Math.min(4, Math.ceil(needed / 2));

  // Parallelise les scenes Replicate
  const sceneResults = await Promise.allSettled(
    scenes.slice(0, Math.ceil(needed / batchSize)).map(async (scene) => {
      const prompt = promptTemplate.replace(/\{scene\}/g, scene).replace(/\{characters\}/g, "1 young male character");
      const seed = Math.floor(Math.random() * 1000000);

      const replicateRes = await fetch(
        `https://api.replicate.com/v1/models/${owner}/${model}/predictions`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
          body: JSON.stringify({
            version,
            input: {
              prompt,
              negative_prompt: negPrompt || undefined,
              width, height,
              num_inference_steps: steps,
              guidance_scale: guidance,
              num_outputs: batchSize,
              seed,
              scheduler: "DPMSolverMultistep",
            },
          }),
        },
      );
      if (!replicateRes.ok) return [];
      const pred = await replicateRes.json();
      const output = await pollReplicate(pred.id);
      if (output && Array.isArray(output)) {
        return output.filter((u): u is string => typeof u === "string" && u.startsWith("http"));
      }
      return [];
    })
  );

  for (const result of sceneResults) {
    if (result.status === "fulfilled" && result.value.length > 0) {
      generated.push(...result.value);
    }
  }

  // Upload generated images to Supabase storage for persistence
  const uploadedUrls: string[] = [];
  for (let i = 0; i < generated.length; i++) {
    try {
      const imgBuf = await (await fetch(generated[i])).arrayBuffer();
      const fileName = `bootstraps/${styleSlug}/${Date.now()}_${i}.png`;
      const { data, error } = await supabase.storage
        .from("planche-assets")
        .upload(fileName, new Uint8Array(imgBuf), { contentType: "image/png", upsert: true });
      if (!error && data) {
        const { data: { publicUrl } } = supabase.storage.from("planche-assets").getPublicUrl(fileName);
        uploadedUrls.push(publicUrl);
      }
    } catch { continue; }
  }

  return uploadedUrls.length > 0 ? uploadedUrls : generated;
}

async function pollReplicate(predictionId: string, maxWait = 120): Promise<any> {
  for (let i = 0; i < maxWait; i++) {
    await new Promise((r) => setTimeout(r, 2000));
    try {
      const res = await fetch(`https://api.replicate.com/v1/predictions/${predictionId}`, {
        headers: { Authorization: `Bearer ${REPLICATE_API_KEY}` },
      });
      if (!res.ok) return null;
      const data = await res.json();
      if (data.status === "succeeded") {
        return data.output;
      }
      if (data.status === "failed") return null;
    } catch { return null; }
  }
  return null;
}
