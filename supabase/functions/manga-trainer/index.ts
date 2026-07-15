import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import JSZip from "npm:jszip@3.10.1";

const REPLICATE_API_KEY = Deno.env.get("REPLICATE_API_KEY") ?? "";
const REPLICATE_BASE = "https://api.replicate.com/v1";
// Compte Replicate propriétaire de la destination du LoRA (configurable, pas hardcodé).
const REPLICATE_DEST_OWNER = Deno.env.get("REPLICATE_DEST_OWNER") ?? "krislester900";

// Bloque les URLs pointant vers des hôtes internes / métadonnées (mitigation SSRF).
function isSafeHttpUrl(url: string): boolean {
  try {
    const u = new URL(url);
    if (u.protocol !== "http:" && u.protocol !== "https:") return false;
    const host = u.hostname.toLowerCase();
    if (host === "localhost" || host.endsWith(".localhost") || host === "0.0.0.0") return false;
    if (host === "[::1]" || host === "::1") return false;
    if (/^127\./.test(host) || /^10\./.test(host) || /^192\.168\./.test(host)) return false;
    if (/^172\.(1[6-9]|2\d|3[01])\./.test(host)) return false;
    if (/^169\.254\./.test(host)) return false; // inclut 169.254.169.254 (metadata cloud)
    return true;
  } catch {
    return false;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "POST", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "POST requis" }), { status: 405, headers: { "Content-Type": "application/json" } });
  }

  try {
    const authHeader = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Non authentifié" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const cronSecret = Deno.env.get("CRON_SECRET") ?? "";
    const cronHeader = req.headers.get("x-cron-secret") ?? "";
    const isAdmin = authHeader === cronSecret || cronHeader === cronSecret;

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    let userId = "";
    if (!isAdmin) {
      const { data: { user } } = await supabase.auth.getUser(authHeader);
      if (!user) {
        return new Response(JSON.stringify({ error: "Utilisateur non trouvé" }), { status: 401, headers: { "Content-Type": "application/json" } });
      }
      userId = user.id;
    }

    const body = await req.json();
    const { action, style_slug, image_url, image_urls } = body;

    if (!action) {
      return new Response(JSON.stringify({ error: "action requis" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    if (action === "list_ready") {
      // Styles with ≥50 references (reduced from 200 for bootstrap)
      const { data: refStyles } = await supabase
        .from("ai_manga_styles")
        .select("slug, name, reference_count, generation_count, training_status")
        .or(`training_status.eq.ready,training_status.eq.untrained,training_status.eq.collecting`)
        .or(`reference_count.gte.50,generation_count.gte.100`)
        .order("name", { ascending: true });

      const ready = (refStyles ?? []).filter((s: any) => {
        // Ready if: status=ready, OR (status!=training and has enough refs or generations)
        if (s.training_status === "training") return false;
        if (s.training_status === "ready") return true;
        if (s.reference_count >= 50) return true;
        if ((s.generation_count ?? 0) >= 100) return true;
        return false;
      });

      return new Response(JSON.stringify(ready), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    if (!style_slug) {
      return new Response(JSON.stringify({ error: "style_slug requis" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const { data: style } = await supabase
      .from("ai_manga_styles")
      .select("*")
      .eq("slug", style_slug)
      .limit(1)
      .single();

    if (!style) {
      return new Response(JSON.stringify({ error: "Style non trouvé" }), { status: 404, headers: { "Content-Type": "application/json" } });
    }

    if (action === "add_reference") {
      if (!image_url || !isSafeHttpUrl(image_url)) {
        return new Response(JSON.stringify({ error: "image_url invalide" }), { status: 400, headers: { "Content-Type": "application/json" } });
      }
      if (!isAdmin && style.user_id && style.user_id !== userId) {
        return new Response(JSON.stringify({ error: "Style non autorisé" }), { status: 403, headers: { "Content-Type": "application/json" } });
      }
      await supabase.from("ai_manga_references").insert({
        user_id: userId, style_id: style.id, image_url, source: "upload",
      });
      const { data: newCount } = await supabase.rpc("increment_style_counter", {
        p_style_id: style.id,
        p_field: "reference_count",
        p_delta: 1,
      });
      const total = typeof newCount === "number" ? newCount : (style.reference_count ?? 0) + 1;
      const isReady = total >= 50 || (style.generation_count ?? 0) >= 100;
      await supabase.from("ai_manga_styles").update({
        training_status: isReady ? "ready" : "collecting",
      }).eq("id", style.id);
      return new Response(JSON.stringify({ ok: true, reference_count: total, ready: isReady }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    if (action === "start_training") {
      if (!REPLICATE_API_KEY) {
        return new Response(JSON.stringify({ error: "REPLICATE_API_KEY non configurée" }), { status: 500, headers: { "Content-Type": "application/json" } });
      }

      const { data: refs } = await supabase
        .from("ai_manga_references")
        .select("image_url")
        .eq("style_id", style.id)
        .limit(500);

      if (!refs || refs.length < 5) {
        return new Response(JSON.stringify({ error: `Minimum 5 images requises (${refs?.length ?? 0}/5)` }), { status: 400, headers: { "Content-Type": "application/json" } });
      }

      const artistTags = style.style_tags?.join(", ") ?? "";
      const instancePrompt = `masterpiece, best quality, ${style.name} manga art style by ${style.mangaka}, ${artistTags}`;

      const { data: job, error: jobError } = await supabase.from("ai_training_jobs").insert({
        style_id: style.id,
        status: "preparing",
        instance_prompt: instancePrompt,
        reference_count: refs.length,
      }).select("id").single();

      if (jobError || !job) {
        return new Response(JSON.stringify({ error: "Erreur création job" }), { status: 500, headers: { "Content-Type": "application/json" } });
      }

      await supabase.from("ai_manga_styles").update({ training_status: "training" }).eq("id", style.id);

      try {
        const zip = new JSZip();
        const captionLines: string[] = [];
        const images = refs
          .filter((r: any) => isSafeHttpUrl(r.image_url))
          .map((r: any, i: number) => ({ id: r.id, url: r.image_url, index: i }));

        const dlResults = await Promise.allSettled(
          images.map((img) =>
            fetch(img.url).then(async (r) => {
              if (!r.ok) throw new Error(`HTTP ${r.status}`);
              const buf = await r.arrayBuffer();
              return { id: img.id, index: img.index, buffer: buf, ext: img.url.match(/\.(png|jpg|jpeg|webp)/i)?.[1] ?? "jpg" };
            })
          )
        );

        let addedCount = 0;
        const trainedIds: number[] = [];
        for (const res of dlResults) {
          if (res.status === "fulfilled") {
            const { id: refId, index, buffer, ext } = res.value;
            const fname = `${String(index).padStart(3, "0")}.${ext}`;
            zip.file(fname, buffer);
            captionLines.push(`{"image": "${fname}", "caption": "masterpiece, best quality, ${style.slug} manga panel art style by ${style.mangaka}, manga panel, monochrome, lineart, screentone"}`);
            trainedIds.push(refId);
            addedCount++;
          }
        }

        // Marquer les images téléchargées
        if (trainedIds.length > 0) {
          await supabase.from("ai_manga_references").update({
            used_in_training: true,
            trained_at: new Date().toISOString(),
            downloaded: true,
          }).in("id", trainedIds);
        }

        if (addedCount < 5) {
          throw new Error(`Seulement ${addedCount} images téléchargées sur ${refs.length}`);
        }

        zip.file("metadata.jsonl", captionLines.join("\n"));
        const zipBuf = await zip.generateAsync({ type: "uint8array" });

        const storagePath = `training/${style.slug}-${Date.now()}.zip`;
        const { error: uploadErr } = await supabase.storage.from("training").upload(storagePath, zipBuf, {
          contentType: "application/zip", upsert: true,
        });

        if (uploadErr) throw new Error(`Upload zip: ${uploadErr.message}`);
        const { data: { publicUrl } } = supabase.storage.from("training").getPublicUrl(storagePath);

        await supabase.from("ai_training_jobs").update({ status: "training" }).eq("id", job.id);

        const SDXL_VERSION = "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc";
        const replicateRes = await fetch(`${REPLICATE_BASE}/models/stability-ai/sdxl/versions/${SDXL_VERSION}/trainings`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
          body: JSON.stringify({
            destination: `${REPLICATE_DEST_OWNER}/sdxl-manga-${style.slug}`,
            input: {
              input_images: publicUrl,
              token_string: "MANGA_STYLE",
              caption_prefix: `masterpiece, best quality, MANGA_STYLE manga art style, manga panel, monochrome, lineart, screentone, `,
              max_train_steps: 2000,
              unet_learning_rate: 1e-4,
              resolution: 768,
              lora_rank: 32,
            },
          }),
        });

        if (!replicateRes.ok) {
          const errText = await replicateRes.text();
          throw new Error(`Replicate training error: ${errText}`);
        }

        const training = await replicateRes.json();
        const replicateJobId = training.id;

        await supabase.from("ai_training_jobs").update({
          replicate_job_id: replicateJobId,
          status: "training",
          started_at: new Date().toISOString(),
        }).eq("id", job.id);

        return new Response(JSON.stringify({
          status: "training_started",
          job_id: job.id,
          replicate_id: replicateJobId,
          message: `Entraînement lancé avec ${addedCount} images. 15-30 minutes.`,
        }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        await supabase.from("ai_training_jobs").update({ status: "failed", error_message: msg }).eq("id", job.id);
        await supabase.from("ai_manga_styles").update({ training_status: "failed" }).eq("id", style.id);
        console.error("manga-trainer start_training error:", msg);
        return new Response(JSON.stringify({ error: "Erreur interne" }), { status: 500, headers: { "Content-Type": "application/json" } });
      }
    }

    if (action === "add_composite_refs") {
      // Improvement loop: add successfully generated panel images as references
      if (!image_urls || !Array.isArray(image_urls) || image_urls.length === 0) {
        return new Response(JSON.stringify({ error: "image_urls[] requis" }), { status: 400, headers: { "Content-Type": "application/json" } });
      }
      if (!image_urls.every((u) => typeof u === "string" && isSafeHttpUrl(u))) {
        return new Response(JSON.stringify({ error: "URL invalide (hôte non autorisé)" }), { status: 400, headers: { "Content-Type": "application/json" } });
      }

      // Count existing refs for this style
      const { count: existingCount } = await supabase
        .from("ai_manga_references")
        .select("*", { count: "exact", head: true })
        .eq("style_id", style.id);

      const remaining = Math.max(0, 500 - (existingCount ?? 0));
      const toInsert = image_urls.slice(0, Math.min(remaining, image_urls.length));

      if (toInsert.length === 0) {
        return new Response(JSON.stringify({ ok: true, added: 0, total: existingCount ?? 0 }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      // Deduplicate against existing
      const existingUrls = new Set<string>();
      for (let i = 0; i < toInsert.length; i += 50) {
        const chunk = toInsert.slice(i, i + 50);
        const { data: existing } = await supabase
          .from("ai_manga_references")
        .select("id, image_url")
          .in("image_url", chunk);
        if (existing) for (const row of existing) existingUrls.add(row.image_url);
      }

      let added = 0;
      for (const url of toInsert) {
        if (existingUrls.has(url)) continue;
        await supabase.from("ai_manga_references").insert({
          style_id: style.id,
          image_url: url,
          source: "generated",
          caption: `generated-${style.slug}`,
        });
        added++;
      }

      const { data: newTotal } = await supabase.rpc("increment_style_counter", {
        p_style_id: style.id,
        p_field: "reference_count",
        p_delta: added,
      });
      await supabase.rpc("increment_style_counter", {
        p_style_id: style.id,
        p_field: "generation_count",
        p_delta: 1,
      });
      const total = typeof newTotal === "number" ? newTotal : (existingCount ?? 0) + added;
      const isReady = total >= 50 || (style.generation_count ?? 0) >= 100;
      await supabase.from("ai_manga_styles").update({
        training_status: isReady ? "ready" : "collecting",
      }).eq("id", style.id);

      return new Response(JSON.stringify({ ok: true, added, total: newTotal, ready: isReady }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    if (action === "test_download") {
      const { data: refs } = await supabase
        .from("ai_manga_references")
        .select("image_url")
        .eq("style_id", style.id)
        .limit(10);

      if (!refs || refs.length === 0) {
        return new Response(JSON.stringify({ ok: false, error: "Aucune image de référence", refs: 0 }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      const images = refs
        .filter((r: any) => isSafeHttpUrl(r.image_url))
        .map((r: any, i: number) => ({ url: r.image_url, index: i }));
      const dlResults = await Promise.allSettled(
        images.map((img) =>
          fetch(img.url).then(async (r) => {
            if (!r.ok) throw new Error(`HTTP ${r.status}`);
            const buf = await r.arrayBuffer();
            return { index: img.index, size: buf.byteLength, ext: img.url.match(/\.(png|jpg|jpeg|webp)/i)?.[1] ?? "jpg", ok: true };
          })
        )
      );

      let ok = 0, fail = 0;
      for (const res of dlResults) {
        if (res.status === "fulfilled" && res.value.ok) ok++;
        else fail++;
      }

      return new Response(JSON.stringify({ ok: true, downloaded: ok, failed: fail, total: refs.length }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    if (action === "status") {
      const { data: latestJob } = await supabase
        .from("ai_training_jobs")
        .select("*")
        .eq("style_id", style.id)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      // Lazy polling Replicate : si job en cours avec replicate_job_id, on check et update
      if (latestJob && latestJob.status === "training" && latestJob.replicate_job_id) {
        try {
          const res = await fetch(`${REPLICATE_BASE}/trainings/${latestJob.replicate_job_id}`, {
            headers: { Authorization: `Bearer ${REPLICATE_API_KEY}` },
          });
          if (res.ok) {
            const data = await res.json();
            if (data.status === "succeeded") {
              const versionId = data.output?.version;
              if (versionId) {
                await supabase.from("ai_manga_styles").update({
                  model_version: versionId,
                  training_status: "ready",
                  lora_url: `replicate://${REPLICATE_DEST_OWNER}/sdxl-manga-${style.slug}`,
                }).eq("id", style.id);
                await supabase.from("ai_training_jobs").update({
                  status: "completed", lora_url: `replicate://${REPLICATE_DEST_OWNER}/sdxl-manga-${style.slug}`,
                  completed_at: new Date().toISOString(), progress: 1.0,
                }).eq("id", latestJob.id);
              }
            } else if (data.status === "failed") {
              await supabase.from("ai_training_jobs").update({
                status: "failed", error_message: data.error ?? "Échec Replicate",
              }).eq("id", latestJob.id);
              await supabase.from("ai_manga_styles").update({ training_status: "failed" }).eq("id", style.id);
            } else if (data.status === "processing") {
              await supabase.from("ai_training_jobs").update({ progress: 0.5 }).eq("id", latestJob.id);
            }
          }
        } catch {
          // silencieux — retry au prochain appel
        }
      }

      // Re-read after potential update
      const { data: refreshedJob } = await supabase
        .from("ai_training_jobs")
        .select("*")
        .eq("style_id", style.id)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      return new Response(JSON.stringify({
        training_status: style.training_status,
        reference_count: style.reference_count,
        job: refreshedJob ?? null,
        lora_url: style.lora_url,
      }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    return new Response(JSON.stringify({ error: "Action inconnue" }), { status: 400, headers: { "Content-Type": "application/json" } });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error("manga-trainer error:", msg);
    return new Response(JSON.stringify({ error: "Erreur interne" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

