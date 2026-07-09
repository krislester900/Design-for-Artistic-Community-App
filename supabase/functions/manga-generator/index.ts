import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const REPLICATE_API_KEY = Deno.env.get("REPLICATE_API_KEY") ?? "";
const REPLICATE_BASE = "https://api.replicate.com/v1";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET, POST", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }

  const url = new URL(req.url);
  const predictionId = url.searchParams.get("prediction_id");

  if (req.method === "GET" && predictionId) {
    return checkStatus(predictionId);
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

    const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Utilisateur non trouvé" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const body = await req.json();
    const { prompt, style_slug, pose_image, seed } = body;

    if (!prompt || !style_slug) {
      return new Response(JSON.stringify({ error: "prompt et style_slug requis" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const { data: style } = await supabase
      .from("ai_manga_styles")
      .select("*")
      .eq("slug", style_slug)
      .limit(1)
      .single();

    if (!style) {
      return new Response(JSON.stringify({ error: "Style mangaka non trouvé" }), { status: 404, headers: { "Content-Type": "application/json" } });
    }

    if (!REPLICATE_API_KEY) {
      return new Response(JSON.stringify({ error: "REPLICATE_API_KEY non configurée" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }

    const qualityTags = "masterpiece, best quality, absurdres, highres";
    const animatedNeg = "lowres, bad anatomy, bad hands, text, error, missing finger, extra digits, fewer digits, cropped, worst quality, low quality, low score, bad score, average score, signature, watermark, username, blurry, ugly, deformed, mutated";
    const rawPrompt = style.prompt_template.replace("{prompt}", prompt);
    const finalPrompt = `${qualityTags}, ${rawPrompt}`;
    const negPrompt = style.negative_prompt ? `${animatedNeg}, ${style.negative_prompt}` : animatedNeg;

    const modelInput: Record<string, any> = {
      prompt: finalPrompt,
      negative_prompt: negPrompt,
      width: style.width,
      height: style.height,
      num_inference_steps: style.num_inference_steps ?? 25,
      guidance_scale: Number(style.guidance_scale ?? 6),
      scheduler: "Euler a",
      num_outputs: 1,
    };

    if (seed != null) {
      modelInput.seed = seed;
    }

    if (style.lora_url) {
      modelInput.lora_urls = [style.lora_url];
      modelInput.lora_scales = [Number(style.lora_scale ?? 0.8)];
    }

    if (pose_image) {
      modelInput.controlnet_units = [{
        controlnet_model: "thibaud/controlnet-openpose-sdxl-1.0",
        controlnet_image: pose_image,
        controlnet_weight: 0.8,
      }];
    }

    const replicateRes = await fetch(`${REPLICATE_BASE}/models/${style.model_owner}/${style.model_name}/predictions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
      body: JSON.stringify({ version: style.model_version, input: modelInput }),
    });

    if (!replicateRes.ok) {
      const errText = await replicateRes.text();
      return new Response(JSON.stringify({ error: `Replicate error: ${errText}` }), { status: 502, headers: { "Content-Type": "application/json" } });
    }

    const prediction = await replicateRes.json();
    const predId = prediction.id;

    let result = await pollPrediction(predId);

    if (result.status === "succeeded" && result.output?.[0]) {
      const imageUrl = result.output[0];

      await supabase.from("ai_generations").insert({
        user_id: user.id,
        style_id: style.id,
        prompt: prompt,
        image_url: imageUrl,
        metadata: { fullPrompt: finalPrompt, negativePrompt: negPrompt, model: `${style.model_owner}/${style.model_name}`, seed: seed ?? null },
      });

      await supabase.from("ai_manga_styles").update({ generation_count: style.generation_count + 1 }).eq("id", style.id);

      return new Response(JSON.stringify({ status: "completed", image_url: imageUrl, prediction_id: predId, seed: seed ?? null }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    return new Response(JSON.stringify({ status: "processing", prediction_id: predId, details: result }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

async function pollPrediction(predictionId: string, maxRetries = 30): Promise<any> {
  for (let i = 0; i < maxRetries; i++) {
    const res = await fetch(`${REPLICATE_BASE}/predictions/${predictionId}`, {
      headers: { Authorization: `Bearer ${REPLICATE_API_KEY}` },
    });
    if (!res.ok) break;
    const data = await res.json();
    if (data.status === "succeeded" || data.status === "failed") return data;
    await new Promise((r) => setTimeout(r, 2000));
  }
  return { status: "timeout" };
}

async function checkStatus(predictionId: string) {
  if (!REPLICATE_API_KEY) {
    return new Response(JSON.stringify({ error: "REPLICATE_API_KEY non configurée" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }

  try {
    const res = await fetch(`${REPLICATE_BASE}/predictions/${predictionId}`, {
      headers: { Authorization: `Bearer ${REPLICATE_API_KEY}` },
    });

    if (!res.ok) {
      return new Response(JSON.stringify({ error: "Prédiction non trouvée" }), { status: 404, headers: { "Content-Type": "application/json" } });
    }

    const data = await res.json();
    return new Response(JSON.stringify({
      status: data.status,
      image_url: data.output?.[0] ?? null,
      prediction_id: predictionId,
    }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
