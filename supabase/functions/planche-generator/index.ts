import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") ?? "";
const REPLICATE_API_KEY = Deno.env.get("REPLICATE_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const SDXL = { owner: "rocketdigitalai", name: "animagine-xl-4.0", version: "7af46ee494f1cf196d49a8592737f4eb789e34a5a995751b23a869d19f5dc2ba" };
const DENOISE_STRENGTH = 0.55;

interface PanelLayout { x: number; y: number; w: number; h: number; label: string; }

interface PanelScript {
  panel_index: number;
  scene: string;
  characters: string;
  dialogue: string;
  narration: string;
  framing: string;
  camera_angle: string;
  emotion: string;
  action: string;
}

interface Character {
  name: string;
  appearance: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET, POST", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }

  const url = new URL(req.url);
  const plancheId = url.searchParams.get("planche_id");

  if (req.method === "GET" && plancheId) {
    return handleGetStatus(plancheId);
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "POST requis" }), { status: 405, headers: { "Content-Type": "application/json" } });
  }

  return handleCreate(req);
});

async function handleCreate(req: Request): Promise<Response> {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
    const authHeader = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!authHeader) throw new Error("Non authentifié");

    const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader);
    if (authError || !user) throw new Error("Utilisateur non trouvé");

    const body = await req.json();
    const { scene, style_slug, characters, layout_type, title, page_number, total_pages } = body;

    if (!scene || !style_slug) {
      return new Response(
        JSON.stringify({ error: "scene et style_slug requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const { data: style } = await supabase
      .from("ai_manga_styles")
      .select("*")
      .eq("slug", style_slug)
      .limit(1)
      .single();

    if (!style) {
      return new Response(
        JSON.stringify({ error: "Style non trouvé" }),
        { status: 404, headers: { "Content-Type": "application/json" } },
      );
    }

    let layoutData: { panels: PanelLayout[]; slug: string };

    if (layout_type) {
      const { data: layout } = await supabase
        .from("ai_planche_layouts")
        .select("*")
        .eq("slug", layout_type)
        .limit(1)
        .single();
      layoutData = layout
        ? { panels: layout.layout_data.panels, slug: layout.slug }
        : getDefaultLayout();
    } else {
      layoutData = getDefaultLayout();
    }

    const panelCount = layoutData.panels.length;
    const charList: Character[] = Array.isArray(characters) ? characters : [];

    const panelScripts = await generatePanelScripts(scene, charList, panelCount);

    const { data: planche, error: insertError } = await supabase.from("ai_planches").insert({
      user_id: user.id,
      style_slug,
      layout_slug: layoutData.slug,
      title: title || scene.slice(0, 80),
      page_number: page_number || 1,
      total_pages: total_pages || 1,
      scene_prompt: scene,
      characters: charList,
      status: "generating",
      metadata: { panel_count: panelCount, char_refs: [] },
    }).select().single();

    if (insertError || !planche) {
      return new Response(
        JSON.stringify({ error: "Erreur création planche" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const panelRows = [];
    for (let i = 0; i < panelCount; i++) {
      const l = layoutData.panels[i];
      const script = panelScripts[i] || {
        panel_index: i, scene: "...", characters: "", dialogue: "",
        narration: "", framing: "medium", camera_angle: "eye-level",
        emotion: "neutre", action: "",
      };
      const promptSdxl = buildPanelPrompt(script, style, charList);
      panelRows.push({
        planche_id: planche.id,
        panel_index: i,
        x_pct: l.x, y_pct: l.y, width_pct: l.w, height_pct: l.h,
        scene_description: script.scene,
        dialogue: script.dialogue || "",
        narration: script.narration || "",
        prompt_sdxl: promptSdxl,
        status: "pending",
      });
    }

    const { error: panelInsertError } = await supabase.from("ai_planche_panels").insert(panelRows);
    if (panelInsertError) {
      await supabase.from("ai_planches").update({
        status: "failed",
        metadata: { error: panelInsertError.message },
      }).eq("id", planche.id);
      return new Response(
        JSON.stringify({ error: "Erreur création panels" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(JSON.stringify({
      planche_id: planche.id,
      status: "generating",
      panel_count: panelCount,
      characters: charList,
      style_slug,
      layout: layoutData,
      message: "Planche créée. Utilise GET ?planche_id= pour suivre la progression.",
    }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
}

async function handleGetStatus(plancheId: string): Promise<Response> {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

    const { data: planche } = await supabase
      .from("ai_planches")
      .select("*")
      .eq("id", plancheId)
      .limit(1)
      .single();

    if (!planche) {
      return new Response(JSON.stringify({ error: "Planche non trouvée" }), { status: 404, headers: { "Content-Type": "application/json" } });
    }

    if (planche.status !== "completed" && planche.status !== "failed") {
      await processNextPendingPanel(supabase, planche);
    }

    const { data: panels } = await supabase
      .from("ai_planche_panels")
      .select("*")
      .eq("planche_id", plancheId)
      .order("panel_index");

    const completed = panels?.filter((p: any) => p.status === "completed").length ?? 0;
    const failed = panels?.filter((p: any) => p.status === "failed").length ?? 0;
    const total = panels?.length ?? 0;

    return new Response(JSON.stringify({
      planche,
      panels,
      total_panels: total,
      completed_panels: completed,
      failed_panels: failed,
      progress: total > 0 ? Math.round((completed + failed) / total * 100) : 0,
    }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}

async function processNextPendingPanel(supabase: any, planche: any) {
  const { data: style } = await supabase
    .from("ai_manga_styles")
    .select("*")
    .eq("slug", planche.style_slug)
    .limit(1)
    .single();

  if (!style) return;

  const charList: Character[] = Array.isArray(planche.characters) ? planche.characters : [];
  let charRefs: string[] = planche.metadata?.char_refs ?? [];

  // Step 1: generate character reference portraits if needed
  if (charList.length > 0 && charRefs.length === 0) {
    for (const ch of charList) {
      const refUrl = await generateCharacterRef(ch, style);
      if (refUrl) charRefs.push(refUrl);
    }
    if (charRefs.length > 0) {
      await supabase.from("ai_planches").update({
        metadata: { ...(planche.metadata ?? {}), char_refs: charRefs },
      }).eq("id", planche.id);
    }
  }

  // Step 2: generate next pending panel (with or without img2img ref)
  const { data: pending } = await supabase
    .from("ai_planche_panels")
    .select("*")
    .eq("planche_id", planche.id)
    .eq("status", "pending")
    .limit(1);

  if (!pending || pending.length === 0) return;

  const panel = pending[0];
  await supabase.from("ai_planche_panels").update({ status: "generating" }).eq("id", panel.id);

  const imageUrl = await generateSdxlImage(
    panel.prompt_sdxl,
    style,
    charRefs.length > 0 ? charRefs[0] : null,
  );

  if (imageUrl) {
    await supabase.from("ai_planche_panels").update({ status: "completed", image_url: imageUrl }).eq("id", panel.id);
  } else {
    await supabase.from("ai_planche_panels").update({ status: "failed" }).eq("id", panel.id);
  }

  // Step 3: check if all panels are done → update planche status
  const { data: remaining } = await supabase
    .from("ai_planche_panels")
    .select("id")
    .eq("planche_id", planche.id)
    .in("status", ["pending", "generating"]);

  if (!remaining || remaining.length === 0) {
    const { data: allPanels } = await supabase
      .from("ai_planche_panels")
      .select("status")
      .eq("planche_id", planche.id);

    const allCompleted = allPanels?.every((p: any) => p.status === "completed") ?? false;
    await supabase.from("ai_planches").update({ status: allCompleted ? "completed" : "failed" }).eq("id", planche.id);
  }
}

async function generateCharacterRef(ch: Character, style: any): Promise<string | null> {
  if (!REPLICATE_API_KEY) return null;

  const qualityTags = "masterpiece, best quality, absurdres, highres";
  const prompt = `${qualityTags}, ${
    style.prompt_template.replace("{prompt}", `close-up portrait of ${ch.name}, ${ch.appearance}`)
  }, manga character portrait, clean lineart, neutral expression, bust up, front facing, highly detailed face, distinct facial features, recognizable character design`;

  const input = {
    prompt,
    negative_prompt: style.negative_prompt || "lowres, bad anatomy, bad hands, text, error, missing finger, extra digits, fewer digits, cropped, worst quality, low quality, low score, bad score, average score, signature, watermark, username, blurry, ugly, deformed, photorealistic, 3d",
    width: 768,
    height: 768,
    num_inference_steps: 25,
    guidance_scale: 6,
    scheduler: "Euler a",
    num_outputs: 1,
  };

  if (style.lora_url) {
    input.lora_urls = [style.lora_url];
    input.lora_scale = Number(style.lora_scale ?? 0.8);
  }

  const res = await fetch(`https://api.replicate.com/v1/models/${SDXL.owner}/${SDXL.name}/predictions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
    body: JSON.stringify({ version: SDXL.version, input }),
  });

  if (!res.ok) return null;
  const prediction = await res.json();
  return pollReplicate(prediction.id, ch.name);
}

async function pollReplicate(predictionId: string, label: string): Promise<string | null> {
  for (let i = 0; i < 60; i++) {
    const res = await fetch(`https://api.replicate.com/v1/predictions/${predictionId}`, {
      headers: { Authorization: `Bearer ${REPLICATE_API_KEY}` },
    });
    if (!res.ok) break;
    const data = await res.json();
    if (data.status === "succeeded") return data.output?.[0] || null;
    if (data.status === "failed") return null;
    await new Promise((r) => setTimeout(r, 3000));
  }
  return null;
}

async function generatePanelScripts(scene: string, characters: Character[], panelCount: number): Promise<PanelScript[]> {
  if (!GROQ_API_KEY) return generateFallbackScripts(scene, panelCount);

  try {
    const charSection = characters.length > 0
      ? "PERSONNAGES :\n" + characters.map((c, i) =>
        `${i + 1}. ${c.name} — ${c.appearance}`
      ).join("\n")
      : "Pas de personnages définis.";

    const systemPrompt = `Tu es un **scénariste et storyboarder manga** expert (style gekiga/shonen/seinen).
Tu découpes une scène en EXACTEMENT ${panelCount} cases pour une planche de manga.

RÈGLES NARRATIVES MANGA :
- Case 1 : plan d'ensemble ou d'ambiance (établir le lieu, la météo, l'émotion)
- Cases 2 à ${panelCount - 1} : montée dramatique, alterner plans larges et gros plans
- Dernière case : climax ou cliffhanger (gros plan ou plan large poignant)
- Utiliser le rythme : 1 case = 1 action principale

Pour CHAQUE case, fournis ces champs :
- scene : description visuelle du décor + action + émotion (riche, sensorielle)
- characters : nom du/des personnages présents + leur état émotionnel
- dialogue : réplique en français (vide si case muette)
- narration : texte de narration/hors-champ (vide si pas de narration)
- framing : wide | medium | close-up | extreme-close-up
- camera_angle : eye-level | high-angle | low-angle | bird | worm
- emotion : l'émotion dominante de la case
- action : l'action principale en 1 phrase courte

Retourne UNIQUEMENT un JSON array valide. Exemple :
[
  {"panel_index":0,"scene":"...","characters":"...","dialogue":"","narration":"","framing":"wide","camera_angle":"high-angle","emotion":"mélancolie","action":"..."},
  ...
]`;

    const userPrompt = `SCÈNE À DÉCOUPER : ${scene}

${charSection}

NOMBRE DE CASES : ${panelCount}

Génère un découpage narratif professionnel avec progression dramatique.`;

    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${GROQ_API_KEY}` },
      body: JSON.stringify({
        model: "llama3-70b-8192",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 4000,
      }),
    });

    const data = await res.json();
    const content = data.choices?.[0]?.message?.content ?? "";

    const jsonMatch = content.match(/\[[\s\S]*\]/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
  } catch {
    // fallback silencieux
  }

  return generateFallbackScripts(scene, panelCount);
}

function generateFallbackScripts(scene: string, panelCount: number): PanelScript[] {
  const result: PanelScript[] = [];
  for (let i = 0; i < panelCount; i++) {
    result.push({
      panel_index: i,
      scene: i === 0 ? `Plan large : ${scene}` :
             i === panelCount - 1 ? `Climax : ${scene}` :
             `Plan séquence ${i + 1} : ${scene}`,
      characters: "",
      dialogue: "",
      narration: "",
      framing: i === 0 ? "wide" : i === panelCount - 1 ? "close-up" : "medium",
      camera_angle: "eye-level",
      emotion: "neutre",
      action: "",
    });
  }
  return result;
}

function buildPanelPrompt(script: PanelScript, style: any, characters: Character[]): string {
  let prompt = style.prompt_template.replace("{prompt}", script.scene);

  if (script.characters) {
    prompt += `, featuring ${script.characters}`;
  } else if (characters.length > 0) {
    const names = characters.map((c) => `${c.name}: ${c.appearance}`).join(", ");
    prompt += `, featuring ${names}`;
  }

  if (script.emotion && script.emotion !== "neutre") {
    prompt += `, ${script.emotion} atmosphere`;
  }

  if (script.action) {
    prompt += `, dynamic action: ${script.action}`;
  }

  const framingMap: Record<string, string> = {
    "wide": "wide shot, establishing composition, cinematic framing",
    "medium": "medium shot, balanced composition, clear subject",
    "close-up": "close-up shot, intense expression, detailed face",
    "extreme-close-up": "extreme close-up, dramatic detail, abstract composition",
  };

  prompt += `, ${framingMap[script.framing] || "medium shot"}`;

  const angleMap: Record<string, string> = {
    "eye-level": "eye-level perspective",
    "high-angle": "high-angle shot, character looks small",
    "low-angle": "low-angle shot, dramatic upward perspective",
    "bird": "bird's eye view, overhead composition",
    "worm": "worm's eye view, ground level looking up",
  };

  prompt += `, ${angleMap[script.camera_angle] || "eye-level perspective"}`;

  if (script.narration) {
    prompt += `, text overlay area reserved for narration`;
  }

  if (script.dialogue) {
    prompt += `, dialogue scene, characters speaking`;
  }

  prompt += ", manga panel composition, black and white lineart with screentone, japanese comic style, dynamic inking";

  return prompt;
}

async function generateSdxlImage(prompt: string, style: any, refImageUrl: string | null): Promise<string | null> {
  if (!REPLICATE_API_KEY) return null;

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

  const res = await fetch(`https://api.replicate.com/v1/models/${SDXL.owner}/${SDXL.name}/predictions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
    body: JSON.stringify({ version: SDXL.version, input }),
  });

  if (!res.ok) return null;
  const prediction = await res.json();
  return pollReplicate(prediction.id, "panel");
}

function getDefaultLayout(): { panels: PanelLayout[]; slug: string } {
  return {
    slug: "4-panel",
    panels: [
      { x: 0, y: 0, w: 50, h: 50, label: "Case 1" },
      { x: 50, y: 0, w: 50, h: 50, label: "Case 2" },
      { x: 0, y: 50, w: 50, h: 50, label: "Case 3" },
      { x: 50, y: 50, w: 50, h: 50, label: "Case 4" },
    ],
  };
}
