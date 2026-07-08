import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import JSZip from "npm:jszip@3.10.1";

const REPLICATE_API_KEY = Deno.env.get("REPLICATE_API_KEY") ?? "";
const REPLICATE_BASE = "https://api.replicate.com/v1";

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

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: { user } } = await supabase.auth.getUser(authHeader);
    if (!user) {
      return new Response(JSON.stringify({ error: "Utilisateur non trouvé" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const body = await req.json();
    const { action, style_slug, image_url, image_urls } = body;

    if (!action || !style_slug) {
      return new Response(JSON.stringify({ error: "action et style_slug requis" }), { status: 400, headers: { "Content-Type": "application/json" } });
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
      if (!image_url) {
        return new Response(JSON.stringify({ error: "image_url requis" }), { status: 400, headers: { "Content-Type": "application/json" } });
      }
      await supabase.from("ai_manga_references").insert({
        user_id: user.id, style_id: style.id, image_url, source: "upload",
      });
      const { count } = await supabase.from("ai_manga_references").select("*", { count: "exact", head: true }).eq("style_id", style.id);
      await supabase.from("ai_manga_styles").update({
        reference_count: count ?? 0,
        training_status: count != null && count >= 20 ? "ready" : "collecting",
      }).eq("id", style.id);
      return new Response(JSON.stringify({ ok: true, reference_count: count }), {
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
        .limit(50);

      if (!refs || refs.length < 5) {
        return new Response(JSON.stringify({ error: `Minimum 5 images requises (${refs?.length ?? 0}/5)` }), { status: 400, headers: { "Content-Type": "application/json" } });
      }

      // Prompt descriptif pour l'entraînement LoRA
      // Utilise le nom + mangaka pour un instance_prompt riche
      // qui exploite les 2 encodeurs texte de SDXL
      const instancePrompt = `${style.name} manga art style by ${style.mangaka}`;

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
        const images = refs.map((r, i) => ({ url: r.image_url, index: i }));

        const dlResults = await Promise.allSettled(
          images.map((img) =>
            fetch(img.url).then(async (r) => {
              if (!r.ok) throw new Error(`HTTP ${r.status}`);
              const buf = await r.arrayBuffer();
              return { index: img.index, buffer: buf, ext: img.url.match(/\.(png|jpg|jpeg|webp)/i)?.[1] ?? "jpg" };
            })
          )
        );

        let addedCount = 0;
        for (const res of dlResults) {
          if (res.status === "fulfilled") {
            const { index, buffer, ext } = res.value;
            const fname = `${String(index).padStart(3, "0")}.${ext}`;
            zip.file(fname, buffer);
            captionLines.push(`{"image": "${fname}", "caption": "${style.slug}-artwork style manga panel"}`);
            addedCount++;
          }
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

        const replicateRes = await fetch(`${REPLICATE_BASE}/models/stability-ai/sdxl/trainings`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
          body: JSON.stringify({
            destination: `arteia/sdxl-manga-${style.slug}`,
            input: {
              instance_prompt: instancePrompt,
              class_prompt: "manga artwork, anime comic art, japanese illustration style",
              train_data: publicUrl,
              max_train_steps: 2000,
              learning_rate: 1e-4,
              resolution: 1024,
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

        pollAndUpdate(supabase, job.id, style.id, replicateJobId, style.slug);

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
        return new Response(JSON.stringify({ error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
      }
    }

    if (action === "status") {
      const { data: latestJob } = await supabase
        .from("ai_training_jobs")
        .select("*")
        .eq("style_id", style.id)
        .order("created_at", { ascending: false })
        .limit(1)
        .single();

      return new Response(JSON.stringify({
        training_status: style.training_status,
        reference_count: style.reference_count,
        job: latestJob ?? null,
        lora_url: style.lora_url,
      }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    return new Response(JSON.stringify({ error: "Action inconnue" }), { status: 400, headers: { "Content-Type": "application/json" } });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

async function pollAndUpdate(supabase: any, jobId: number, styleId: number, replicateJobId: string, slug: string) {
  for (let i = 0; i < 60; i++) {
    await new Promise((r) => setTimeout(r, 15000));
    try {
      const res = await fetch(`${REPLICATE_BASE}/trainings/${replicateJobId}`, {
        headers: { Authorization: `Bearer ${REPLICATE_API_KEY}` },
      });
      if (!res.ok) continue;
      const data = await res.json();

      if (data.status === "succeeded") {
        const versionId = data.output?.version;
        if (versionId) {
          await supabase.from("ai_manga_styles").update({
            model_version: versionId,
            training_status: "ready",
            lora_url: `replicate://arteia/sdxl-manga-${slug}`,
          }).eq("id", styleId);
          await supabase.from("ai_training_jobs").update({
            status: "completed", lora_url: `replicate://arteia/sdxl-manga-${slug}`, completed_at: new Date().toISOString(), progress: 1.0,
          }).eq("id", jobId);
        }
        return;
      }

      if (data.status === "failed") {
        await supabase.from("ai_training_jobs").update({ status: "failed", error_message: data.error ?? "Échec" }).eq("id", jobId);
        await supabase.from("ai_manga_styles").update({ training_status: "failed" }).eq("id", styleId);
        return;
      }

      await supabase.from("ai_training_jobs").update({ progress: Math.min(0.95, (i + 1) / 40) }).eq("id", jobId);
    } catch {
      continue;
    }
  }
  await supabase.from("ai_training_jobs").update({ status: "failed", error_message: "Timeout polling" }).eq("id", jobId);
  await supabase.from("ai_manga_styles").update({ training_status: "failed" }).eq("id", styleId);
}
