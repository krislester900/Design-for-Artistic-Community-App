import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Parser from "https://esm.sh/rss-parser@3.13.0";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "POST", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }

  try {
    const auth = req.headers.get("authorization")?.replace("Bearer ", "");
    const cronSecret = Deno.env.get("CRON_SECRET");
    if (cronSecret && auth !== cronSecret) {
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

        const feedUrls = [
          `https://www.pinterest.com/${username}/${boardName}.rss`,
          `https://www.pinterest.com/rss/pin/${username}/${boardName}.rss`,
        ];

        let feed;
        for (const url of feedUrls) {
          try {
            const parser = new Parser();
            feed = await parser.parseURL(url);
            if (feed?.items && feed.items.length > 0) break;
          } catch {
            continue;
          }
        }

        if (!feed || !feed.items || feed.items.length === 0) {
          results.push(`⚠️ ${username}/${boardName}: aucun flux trouvé`);
          continue;
        }

        let newCount = 0;
        for (const item of feed.items) {
          const imageUrl = item.enclosure?.url ?? extractImageFromContent(item.content) ?? "";
          if (!imageUrl) continue;

          const pinUrl = item.link ?? "";
          const existingPinId = pinUrl.match(/\/pin\/(\d+)/)?.[1];
          if (existingPinId && board.last_pin_id && existingPinId <= board.last_pin_id) continue;

          const { data: existing } = await supabase
            .from("ai_manga_references")
            .select("id")
            .eq("image_url", imageUrl)
            .limit(1);

          if (existing && existing.length > 0) continue;

          await supabase.from("ai_manga_references").insert({
            style_id: styleId,
            image_url: imageUrl,
            source: "pinterest",
            caption: item.title ?? "",
          });

          newCount++;
        }

        const latestPinId = feed.items
          .map((i) => i.link?.match(/\/pin\/(\d+)/)?.[1])
          .filter(Boolean)
          .sort()
          .pop();

        const total = (board.total_collected ?? 0) + newCount;
        await supabase.from("ai_pinterest_sources").update({
          last_fetched_at: new Date().toISOString(),
          last_pin_id: latestPinId ?? board.last_pin_id,
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

function extractImageFromContent(htmlContent: string | undefined): string | null {
  if (!htmlContent) return null;
  const match = htmlContent.match(/<img[^>]+src=["']([^"']+)["']/);
  return match?.[1] ?? null;
}
