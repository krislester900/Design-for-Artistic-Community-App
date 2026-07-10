import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TARGET_PER_STYLE = 500;
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
    const cronSecret = Deno.env.get("CRON_SECRET");
    if (cronSecret && auth !== cronSecret && cronHeader !== cronSecret) {
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

    const results: string[] = [];
    const stylesToTrain = new Set<string>();

    for (const board of boards) {
      try {
        const username = board.username;
        const boardName = board.board_name;
        const styleSlug = board.style_slug;
        const styleId = board.style_id;
        const styleName = board.ai_manga_styles?.name ?? styleSlug;
        const currentTotal = board.total_collected ?? 0;
        const styleMeta = board.ai_manga_styles ?? {};

        if (currentTotal >= TARGET_PER_STYLE) {
          results.push(`⏭️ ${username}/${boardName}: déjà ${currentTotal}/${TARGET_PER_STYLE} images`);
          continue;
        }

        const allNewUrls: string[] = [];

        // 1) RSS feed
        try {
          const rssUrl = `https://www.pinterest.com/${username}/${boardName}.rss`;
          const rssResp = await fetch(rssUrl, {
            headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" },
          });
          if (rssResp.ok) {
            const rssXml = await rssResp.text();
            const rssUrls = extractFromRss(rssXml);
            for (const u of rssUrls) allNewUrls.push(u);
          }
        } catch { /* RSS fallback */ }

        // 2) HTML scraping
        if (allNewUrls.length < 100) {
          for (let page = 0; page < 3; page++) {
            const pageParam = page === 0 ? "" : `?page=${page + 1}`;
            const boardUrl = `https://www.pinterest.com/${username}/${boardName}/${pageParam}`;
            try {
              const resp = await fetch(boardUrl, {
                headers: {
                  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                  "Accept": "text/html,application/xhtml+xml",
                  "Accept-Language": "en-US,en;q=0.9",
                },
              });
              if (resp.ok) {
                const html = await resp.text();
                const urls = extractPinterestImages(html);
                for (const u of urls) allNewUrls.push(u);
                if (urls.length < 30) break;
              }
            } catch { break; }
            await new Promise((r) => setTimeout(r, 1500));
          }
        }

        // 3) Bing image search (reliable HTML scraping, no JS required)
        if (allNewUrls.length < 50) {
          try {
            const searchQuery = encodeURIComponent(`${styleName} manga anime artwork art`);
            const bingUrl = `https://www.bing.com/images/search?q=${searchQuery}&count=50`;
            const bingResp = await fetch(bingUrl, {
              headers: {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                "Accept": "text/html,application/xhtml+xml",
                "Accept-Language": "en-US,en;q=0.9",
              },
            });
            if (bingResp.ok) {
              const bingHtml = await bingResp.text();
              const bingUrls = extractBingImages(bingHtml);
              for (const u of bingUrls) allNewUrls.push(u);
            }
          } catch { /* Bing fallback */ }
        }

        // 4) Google Images (second fallback)
        if (allNewUrls.length < 50) {
          try {
            const searchQuery = encodeURIComponent(`${styleName} manga ${username}`);
            const gUrl = `https://www.google.com/search?tbm=isch&q=${searchQuery}&tbs=isz:l`;
            const gResp = await fetch(gUrl, {
              headers: {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                "Accept": "text/html,application/xhtml+xml",
                "Accept-Language": "en-US,en;q=0.9",
              },
            });
            if (gResp.ok) {
              const gHtml = await gResp.text();
              const gUrls = extractGoogleImages(gHtml);
              for (const u of gUrls) allNewUrls.push(u);
            }
          } catch { /* Google fallback */ }
        }

        // 5) Bootstrap via Replicate (generate reference images from style prompt)
        // Only if we have a prompt template AND enough quota remaining
        const needed = TARGET_PER_STYLE - currentTotal;
        if (allNewUrls.length < 50 && needed > 50 && REPLICATE_API_KEY && styleMeta.prompt_template) {
          try {
            const bootUrls = await generateBootstrapImages(supabase, styleId, styleSlug, styleMeta, needed);
            for (const u of bootUrls) allNewUrls.push(u);
            if (bootUrls.length > 0) {
              results.push(`🎨 Bootstrap Replicate: ${bootUrls.length} images générées pour "${styleName}"`);
            }
          } catch (e) {
            results.push(`⚠️ Bootstrap Replicate échoué pour ${styleName}: ${e instanceof Error ? e.message : String(e)}`);
          }
        }

        const uniqueUrls = [...new Set(allNewUrls)];
        if (uniqueUrls.length === 0) {
          results.push(`⚠️ ${username}/${boardName}: aucune image trouvée (RSS+HTML+Bing+Google+Bootstrap)`);
          continue;
        }

        // Déduplication
        const existingUrls = new Set<string>();
        const chunkSize = 50;
        for (let i = 0; i < uniqueUrls.length; i += chunkSize) {
          const chunk = uniqueUrls.slice(i, i + chunkSize);
          const { data: existing } = await supabase
            .from("ai_manga_references")
            .select("image_url")
            .in("image_url", chunk)
            .limit(chunkSize);
          if (existing) for (const row of existing) existingUrls.add(row.image_url);
        }

        let newCount = 0;
        for (const url of uniqueUrls) {
          if (existingUrls.has(url)) continue;
          if (currentTotal + newCount >= TARGET_PER_STYLE) break;
          await supabase.from("ai_manga_references").insert({
            style_id: styleId,
            image_url: url,
            source: url.includes("replicate") ? "generated" : "scrape",
            caption: "",
          });
          newCount++;
        }

        const total = currentTotal + newCount;
        await supabase.from("ai_pinterest_sources").update({
          last_fetched_at: new Date().toISOString(),
          total_collected: total,
          last_error: null,
        }).eq("id", board.id);

        await supabase.from("ai_manga_styles").update({ reference_count: total }).eq("id", styleId);

        results.push(`${newCount > 0 ? "✅" : "⏭️"} ${username}/${boardName}: ${newCount} nouvelles (total: ${total}/${TARGET_PER_STYLE})`);

        if (total >= 200) stylesToTrain.add(styleSlug);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        results.push(`❌ ${board.username}/${board.board_name}: ${msg}`);
        await supabase.from("ai_pinterest_sources").update({ last_error: msg }).eq("id", board.id);
      }
    }

    for (const slug of stylesToTrain) {
      try {
        await fetch(`${supabaseUrl}/functions/v1/manga-trainer`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${cronSecret}` },
          body: JSON.stringify({ action: "start_training", style_slug: slug }),
        });
        results.push(`🚀 Entraînement auto déclenché pour ${slug}`);
      } catch {
        results.push(`⚠️ Échec auto-training pour ${slug}`);
      }
    }

    const totalPins = results.reduce((sum, r) => {
      const m = r.match(/^✅.*?(\d+) nouvelles/);
      return sum + (m ? parseInt(m[1]) : 0);
    }, 0);

    return new Response(JSON.stringify({ ok: true, results, pins_collected: totalPins, styles_ready: Array.from(stylesToTrain) }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

// ---------- Extracteurs ----------

function extractPinterestImages(html: string): string[] {
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
      const clean = u.replace(/\/[0-9]+x\//, "/originals/").replace(/\\u0026/g, "&");
      urls.add(clean);
    }
  }
  return Array.from(urls);
}

function extractBingImages(html: string): string[] {
  const urls = new Set<string>();
  // Bing embeds images in JSON-like src attributes and m attribute
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
      if (u.startsWith("http") && !u.includes("bing.com") && !u.includes("th.bing.com")) {
        urls.add(u);
      }
    }
  }
  // Also normalize Bing thumbnail URLs to full size
  const thumbPattern = /https?:\/\/th\.bing\.com\/th\/id\/([^"&\s]+)/g;
  while ((match = thumbPattern.exec(html)) !== null) {
    urls.add(`https://i.bing.com/th/id/${match[1]}`);
  }
  return Array.from(urls);
}

function extractGoogleImages(html: string): string[] {
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
      if (u.startsWith("http") && !u.includes("google") && !u.includes("gstatic.com")) {
        urls.add(u);
      }
    }
  }
  return Array.from(urls);
}

function extractFromRss(xml: string): string[] {
  const urls = new Set<string>();
  const imgPattern = /<img[^>]+src="(https?:\/\/i\.pinimg\.com\/[^"]+\.(?:jpg|png|webp))"/g;
  let match;
  while ((match = imgPattern.exec(xml)) !== null) urls.add(match[1]);
  if (urls.size > 0) return Array.from(urls);
  // Fallback: parse CDATA description
  const mediaPattern = /<media:content[^>]+url="(https?:\/\/[^"]+\.(?:jpg|png|webp))"/g;
  while ((match = mediaPattern.exec(xml)) !== null) urls.add(match[1]);
  if (urls.size > 0) return Array.from(urls);
  const descPattern = /<description>([^<]+)<\/description>/g;
  while ((match = descPattern.exec(xml)) !== null) {
    const desc = match[1].replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"');
    const imgMatch = desc.match(/https?:\/\/i\.pinimg\.com\/[^\s"']+\.(?:jpg|png|webp)/);
    if (imgMatch) urls.add(imgMatch[0]);
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

  for (const scene of scenes) {
    if (generated.length >= needed) break;
    const prompt = promptTemplate.replace(/\{scene\}/g, scene).replace(/\{characters\}/g, "1 young male character");
    const seed = Math.floor(Math.random() * 1000000);

    try {
      const replicateRes = await fetch(
        `https://api.replicate.com/v1/models/${owner}/${model}/predictions`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${REPLICATE_API_KEY}`,
          },
          body: JSON.stringify({
            version,
            input: {
              prompt,
              negative_prompt: negPrompt || undefined,
              width,
              height,
              num_inference_steps: steps,
              guidance_scale: guidance,
              num_outputs: batchSize,
              seed,
              scheduler: "DPMSolverMultistep",
            },
          }),
        },
      );

      if (!replicateRes.ok) continue;
      const pred = await replicateRes.json();
      const output = await pollReplicate(pred.id);
      if (output && Array.isArray(output)) {
        for (const url of output) {
          if (typeof url === "string" && url.startsWith("http")) {
            generated.push(url);
          }
        }
      }
    } catch { continue; }
    // Avoid rate limits
    await new Promise((r) => setTimeout(r, 2000));
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
