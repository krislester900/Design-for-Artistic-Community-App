// Interactions avec Replicate (génération SDXL + upscale). Module isolé et testable.

import { makeLogger, withRetry } from "./logger.ts";

const REPLICATE_API_KEY = Deno.env.get("REPLICATE_API_KEY") ?? "";
const REPLICATE_BASE = "https://api.replicate.com/v1";

const SDXL = { owner: "rocketdigitalai", name: "animagine-xl-4.0", version: "7af46ee494f1cf196d49a8592737f4eb789e34a995751b23a869d19f5dc2ba" };
const SDXL_FALLBACK = { owner: "stability-ai", name: "stable-diffusion-xl-1024-aesthetic", version: "8f5584faab4dbb876f1a7fce6d98700abc9aeff489caa59336a0753989440cad" };
const UPSCALER = { owner: "nightmareai", name: "real-esrgan", version: "42fed1c4974146d4d2414e2be2c5277c7fcf05fcc3a73abf41610695738c1d7b" };
const DENOISE_STRENGTH = 0.55;

export { SDXL, REPLICATE_API_KEY };

export async function replicatePredict(model: { owner: string; name: string; version: string }, input: any, label: string): Promise<string | null> {
  // Primary model
  const url = `https://api.replicate.com/v1/models/${SDXL.owner}/${SDXL.name}/predictions`;
  const primaryRes = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
    body: JSON.stringify({ version: SDXL.version, input }),
  });
  if (primaryRes.ok) {
    const pred = await primaryRes.json();
    return pollReplicate(pred.id, label);
  }
  // Fallback model
  console.warn(`[${label}] fallback vers SDXL standard`);
  const fbUrl = `https://api.replicate.com/v1/models/${SDXL_FALLBACK.owner}/${SDXL_FALLBACK.name}/predictions`;
  const fbRes = await fetch(fbUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
    body: JSON.stringify({ version: SDXL_FALLBACK.version, input }),
  });
  if (!fbRes.ok) return null;
  const fbPred = await fbRes.json();
  return pollReplicate(fbPred.id, `${label}-fallback`);
}

export async function pollReplicate(predictionId: string, label: string): Promise<string | null> {
  for (let i = 0; i < 60; i++) {
    try {
      const res = await fetch(`https://api.replicate.com/v1/predictions/${predictionId}`, {
        headers: { Authorization: `Bearer ${REPLICATE_API_KEY}` },
      });
      if (!res.ok) return null;
      const data = await res.json();
      if (data.status === "succeeded") return data.output?.[0] || null;
      if (data.status === "failed") return null;
    } catch {
      // Network error transitoire — on réessaie
    }
    await new Promise((r) => setTimeout(r, 3000));
  }
  return null;
}

export async function generateSdxlImage(
  prompt: string,
  style: any,
  refImageUrl: string | null,
  poseImageUrl: string | null = null,
): Promise<string | null> {
  const log = makeLogger("generateSdxlImage");
  if (!REPLICATE_API_KEY) {
    log.warn("REPLICATE_API_KEY manquante");
    return null;
  }

  const qualityTags = "masterpiece, best quality, absurdres, highres";
  const animNeg = "lowres, bad anatomy, bad hands, text, error, missing finger, extra digits, fewer digits, cropped, worst quality, low quality, low score, bad score, average score, signature, watermark, username, blurry, ugly, deformed";
  const finalPrompt = `${qualityTags}, ${prompt}`;
  const negPrompt = style.negative_prompt ? `${animNeg}, ${style.negative_prompt}` : animNeg;

  const input: Record<string, any> = {
    prompt: finalPrompt,
    negative_prompt: negPrompt,
    width: style.width || 1024,
    height: style.height || 1024,
    num_inference_steps: 25,
    guidance_scale: Number(style.guidance_scale) || 6,
    scheduler: "Euler a",
    num_outputs: 1,
  };

  if (refImageUrl) {
    input.image = refImageUrl;
    input.denoising_strength = DENOISE_STRENGTH;
    input.prompt_strength = 0.8;
  }

  if (style.lora_url) {
    input.lora_urls = [style.lora_url];
    input.lora_scale = Number(style.lora_scale ?? 0.8);
  }

  if (poseImageUrl) {
    input.controlnet_units = [{
      controlnet_model: "thibaud/controlnet-openpose-sdxl-1.0",
      controlnet_image: poseImageUrl,
      controlnet_weight: 0.8,
    }];
  }

  const result = await withRetry(() => replicatePredict(SDXL, input, "panel"), "panel", 2);
  if (!result) log.error("Échec génération image après retry+fallback", { prompt: prompt.slice(0, 80) });
  return result;
}

export async function upscaleImage(imageUrl: string): Promise<string | null> {
  const log = makeLogger("upscaleImage");
  if (!REPLICATE_API_KEY) {
    log.warn("REPLICATE_API_KEY manquante");
    return null;
  }
  const result = await withRetry(async () => {
    const res = await fetch(`https://api.replicate.com/v1/models/${UPSCALER.owner}/${UPSCALER.name}/predictions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
      body: JSON.stringify({ version: UPSCALER.version, input: { image: imageUrl, scale: 2, face_enhance: false } }),
    });
    if (!res.ok) return null;
    const pred = await res.json();
    return pollReplicate(pred.id, "upscale");
  }, "upscale", 2);
  if (!result) log.error("Upscale échoué après retry");
  return result;
}
