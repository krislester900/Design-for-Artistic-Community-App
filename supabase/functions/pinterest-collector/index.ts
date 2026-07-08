import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
      .select("*, ai_manga_styles!inner(slug, name, training_status, reference_count)")
      .eq("is_active", true);

    if (!boards || boards.length === 0) {
      return new Response(JSON.stringify({ ok: true, message: "Aucun board Pinterest configuré" }), {
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
        const boardUrl = `https://www.pinterest.com/${username}/${boardName}/`;

        // Scraper le HTML de la board Pinterest pour extraire les URLs d'images
        const html = await fetch(boardUrl, {
          headers: {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "text/html,application/xhtml+xml",
          },
        }).then((r) => r.text());

        // Extraire les URLs d'images i.pinimg.com/originals/
        const imageUrls = extractPinterestImages(html);

        if (imageUrls.length === 0) {
          results.push(`⚠️ ${username}/${boardName}: aucune image trouvée sur la page`);
          continue;
        }

        // Filtrer les URLs déjà collectées
        const existingUrls = new Set<string>();
        const chunkSize = 50;
        for (let i = 0; i < imageUrls.length; i += chunkSize) {
          const chunk = imageUrls.slice(i, i + chunkSize);
          const { data: existing } = await supabase
            .from("ai_manga_references")
            .select("image_url")
            .in("image_url", chunk)
            .limit(chunkSize);

          if (existing) {
            for (const row of existing) existingUrls.add(row.image_url);
          }
        }

        let newCount = 0;
        for (const url of imageUrls) {
          if (existingUrls.has(url)) continue;

          await supabase.from("ai_manga_references").insert({
            style_id: styleId,
            image_url: url,
            source: "pinterest",
            caption: "",
          });

          newCount++;
        }

        const total = (board.total_collected ?? 0) + newCount;
        await supabase.from("ai_pinterest_sources").update({
          last_fetched_at: new Date().toISOString(),
          total_collected: total,
          last_error: null,
        }).eq("id", board.id);

        await supabase.from("ai_manga_styles").update({ reference_count: total }).eq("id", styleId);

        results.push(`${newCount > 0 ? "✅" : "⏭️"} ${username}/${boardName}: ${newCount} nouvelles images (total: ${total})`);

        if (newCount >= 10) stylesToTrain.add(styleSlug);
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

    return new Response(JSON.stringify({ ok: true, results }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

function extractPinterestImages(html: string): string[] {
  const urls = new Set<string>();
  const pattern = /https:\/\/i\.pinimg\.com\/originals\/[a-zA-Z0-9]+\/[a-zA-Z0-9]+\/[a-zA-Z0-9]+\.(jpg|png|webp)/g;
  let match;
  while ((match = pattern.exec(html)) !== null) {
    urls.add(match[0]);
  }
  return Array.from(urls);
}
