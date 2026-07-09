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
  pose_description: string;
}

// ---------- OpenPose skeleton library ----------
const POSE_W = 256, POSE_H = 384;
type Kps = [number, number][]; // 18 keypoints [x,y] in POSE_W×POSE_H space

const POSES: Record<string, Kps> = {
  "neutral-stand": [
    [128,60],[128,88],[96,88],[76,118],[64,150],[160,88],[180,118],[192,150],
    [104,160],[104,220],[104,306],[152,160],[152,220],[152,306],
    [118,54],[138,54],[110,58],[146,58],
  ],
  "action-punch": [
    [128,52],[128,80],[96,80],[72,100],[200,96],[160,80],[184,100],[192,130],
    [104,158],[104,218],[104,304],[152,158],[152,218],[152,304],
    [118,46],[138,46],[110,50],[146,50],
  ],
  "action-kick": [
    [128,48],[128,80],[96,80],[76,110],[64,145],[160,80],[180,110],[192,145],
    [104,150],[104,200],[104,260],[152,150],[180,200],[200,280],
    [118,42],[138,42],[110,46],[146,46],
  ],
  "action-run": [
    [128,56],[128,84],[88,84],[68,60],[56,50],[168,84],[188,108],[200,140],
    [100,160],[100,240],[96,310],[156,160],[156,240],[160,310],
    [118,50],[138,50],[110,54],[146,54],
  ],
  "action-jump": [
    [128,36],[128,64],[92,64],[72,38],[58,24],[164,64],[184,90],[196,120],
    [100,144],[100,204],[96,290],[156,144],[156,204],[160,290],
    [118,30],[138,30],[110,34],[146,34],
  ],
  "action-crouch": [
    [128,52],[128,80],[92,80],[64,90],[48,110],[164,80],[192,90],[208,110],
    [100,180],[100,250],[96,330],[156,180],[156,250],[160,330],
    [118,46],[138,46],[110,50],[146,50],
  ],
  "action-point": [
    [128,58],[128,86],[96,86],[76,116],[220,80],[160,86],[180,116],[192,148],
    [104,158],[104,218],[104,304],[152,158],[152,218],[152,304],
    [118,52],[138,52],[110,56],[146,56],
  ],
  "action-duel": [
    [128,56],[128,84],[88,84],[60,100],[44,130],[168,84],[192,100],[208,128],
    [100,158],[100,218],[100,304],[156,158],[156,218],[156,304],
    [118,50],[138,50],[110,54],[146,54],
  ],
  "emotion-sit": [
    [128,36],[128,64],[96,64],[76,94],[64,126],[160,64],[180,94],[192,126],
    [104,160],[124,200],[128,290],[152,160],[132,200],[136,290],
    [118,30],[138,30],[110,34],[146,34],
  ],
  "emotion-collapse": [
    [128,46],[128,74],[96,74],[76,104],[64,136],[160,74],[180,104],[192,136],
    [104,156],[112,220],[100,320],[152,156],[144,220],[156,320],
    [118,40],[138,40],[110,44],[146,44],
  ],
  "action-swing": [
    [128,48],[128,76],[92,76],[60,56],[40,38],[164,76],[192,56],[212,38],
    [104,148],[104,208],[104,294],[152,148],[152,208],[152,294],
    [118,42],[138,42],[110,46],[146,46],
  ],
  "action-defend": [
    [128,58],[128,86],[88,86],[56,70],[44,54],[168,86],[200,70],[212,54],
    [104,158],[104,218],[104,304],[152,158],[152,218],[152,304],
    [118,52],[138,52],[110,56],[146,56],
  ],
};

const SKELETON_CONNECTIONS: [number,number][] = [
  [0,1],[1,2],[2,3],[3,4],[1,5],[5,6],[6,7],
  [1,8],[8,9],[9,10],[1,11],[11,12],[12,13],
  [0,14],[14,16],[0,15],[15,17],[0,1],
];

// ---------- Minimal inline PNG encoder ----------
function crc32(data: Uint8Array): number {
  let c = 0xFFFFFFFF;
  for (let i = 0; i < data.length; i++) {
    c ^= data[i];
    for (let j = 0; j < 8; j++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
  }
  return (c ^ 0xFFFFFFFF) >>> 0;
}

function chunk(type: string, data: Uint8Array): Uint8Array {
  const t = new TextEncoder().encode(type);
  const len = new Uint8Array(4);
  new DataView(len.buffer).setUint32(0, data.length, false);
  const crcIn = new Uint8Array(t.length + data.length);
  crcIn.set(t); crcIn.set(data, t.length);
  const cv = crc32(crcIn);
  const crc = new Uint8Array(4);
  new DataView(crc.buffer).setUint32(0, cv, false);
  const buf = new Uint8Array(8 + t.length + data.length + 4);
  buf.set(len,0); buf.set(t,4); buf.set(data,8); buf.set(crc,8+t.length+data.length);
  return buf;
}

function pngEncode(w: number, h: number, rgba: Uint8Array): Uint8Array {
  const rawRow = w * 4;
  const raw = new Uint8Array(h * (1 + rawRow));
  for (let y = 0; y < h; y++) {
    raw[y * (1 + rawRow)] = 0;
    raw.set(rgba.subarray(y * rawRow, (y + 1) * rawRow), y * (1 + rawRow) + 1);
  }

  // deflate stored blocks
  const MAX = 65535;
  const blocks: Uint8Array[] = [];
  let offset = 0;
  while (offset < raw.length) {
    const sz = Math.min(raw.length - offset, MAX);
    const last = offset + sz >= raw.length;
    const hdr = new Uint8Array(5);
    hdr[0] = last ? 1 : 0;
    hdr[1] = sz & 0xFF; hdr[2] = (sz >> 8) & 0xFF;
    const nlen = (~sz) & 0xFFFF;
    hdr[3] = nlen & 0xFF; hdr[4] = (nlen >> 8) & 0xFF;
    blocks.push(hdr, raw.slice(offset, offset + sz));
    offset += sz;
  }
  const deflated = new Uint8Array(blocks.reduce((s,b) => s + b.length, 0));
  let pos = 0; for (const b of blocks) { deflated.set(b, pos); pos += b.length; }

  const sig = new Uint8Array([137,80,78,71,13,10,26,10]);
  const ihdr = new Uint8Array(13);
  const dv = new DataView(ihdr.buffer);
  dv.setUint32(0, w, false); dv.setUint32(4, h, false);
  ihdr[8]=8; ihdr[9]=6; // RGBA

  const parts = [sig, chunk("IHDR",ihdr), chunk("IDAT",deflated), chunk("IEND",new Uint8Array(0))];
  const total = parts.reduce((s,b) => s + b.length, 0);
  const out = new Uint8Array(total);
  pos = 0; for (const b of parts) { out.set(b, pos); pos += b.length; }
  return out;
}

function renderSkeleton(kps: Kps): Uint8Array {
  const stride = 4;
  const pixels = new Uint8Array(POSE_H * POSE_W * stride);

  function setPx(x: number, y: number) {
    if (x < 0 || x >= POSE_W || y < 0 || y >= POSE_H) return;
    const i = (y * POSE_W + x) * stride;
    pixels[i]=255; pixels[i+1]=255; pixels[i+2]=255; pixels[i+3]=255;
  }

  function line(x1: number, y1: number, x2: number, y2: number) {
    const dx = Math.abs(x2 - x1), dy = Math.abs(y2 - y1);
    const sx = x1 < x2 ? 1 : -1, sy = y1 < y2 ? 1 : -1;
    let err = dx - dy, x = x1, y = y1;
    while (true) {
      setPx(x, y);
      if (x === x2 && y === y2) break;
      const e2 = err * 2;
      if (e2 > -dy) { err -= dy; x += sx; }
      if (e2 < dx) { err += dx; y += sy; }
    }
  }

  function circle(cx: number, cy: number, r: number) {
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        if (dx * dx + dy * dy <= r * r) setPx(cx + dx, cy + dy);
      }
    }
  }

  // Draw connections
  for (const [i, j] of SKELETON_CONNECTIONS) {
    line(kps[i][0], kps[i][1], kps[j][0], kps[j][1]);
  }

  // Draw joints
  for (const [x, y] of kps) {
    circle(x, y, 4);
  }

  // Draw head (larger circle around nose)
  circle(kps[0][0], kps[0][1], 12);

  return pngEncode(POSE_W, POSE_H, pixels);
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
      metadata: { panel_count: panelCount, char_ref_map: {} },
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
        emotion: "neutre", action: "", pose_description: "neutral-stand",
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
        metadata: { pose_description: script.pose_description, camera_angle: script.camera_angle },
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
  let charRefMap: Record<string, Record<string, string>> = planche.metadata?.char_ref_map ?? {};

  // Step 1: generate multi-view character reference portraits if needed
  if (charList.length > 0 && Object.keys(charRefMap).length === 0) {
    for (const ch of charList) {
      const refs = await generateCharacterRefs(ch, style);
      if (refs) charRefMap[ch.name] = refs;
    }
    if (Object.keys(charRefMap).length > 0) {
      await supabase.from("ai_planches").update({
        metadata: { ...(planche.metadata ?? {}), char_ref_map: charRefMap },
      }).eq("id", planche.id);
    }
  }

  // Step 2: generate next pending panel
  const { data: pending } = await supabase
    .from("ai_planche_panels")
    .select("*")
    .eq("planche_id", planche.id)
    .eq("status", "pending")
    .limit(1);

  if (!pending || pending.length === 0) return;

  const panel = pending[0];

  // Step 3: select best character reference for this panel based on camera angle
  const refImageUrl = selectBestRefForPanel(panel, charList, charRefMap);
  await supabase.from("ai_planche_panels").update({ status: "generating" }).eq("id", panel.id);

  const poseUrl = await generatePoseForPanel(supabase, panel, planche.id);

  const imageUrl = await generateSdxlImage(
    panel.prompt_sdxl,
    style,
    refImageUrl,
    poseUrl,
  );

  if (imageUrl) {
    await supabase.from("ai_planche_panels").update({ status: "completed", image_url: imageUrl }).eq("id", panel.id);
  } else {
    await supabase.from("ai_planche_panels").update({ status: "failed" }).eq("id", panel.id);
  }

  // Step 4: check if all panels are done → composite + update planche status
  const { data: remaining } = await supabase
    .from("ai_planche_panels")
    .select("id")
    .eq("planche_id", planche.id)
    .in("status", ["pending", "generating"]);

  if (!remaining || remaining.length === 0) {
    const { data: allPanels } = await supabase
      .from("ai_planche_panels")
      .select("*")
      .eq("planche_id", planche.id)
      .order("panel_index");

    const allCompleted = allPanels?.every((p: any) => p.status === "completed") ?? false;

    if (allCompleted) {
      const { data: layoutRow } = await supabase
        .from("ai_planche_layouts")
        .select("layout_data")
        .eq("slug", planche.layout_slug)
        .limit(1)
        .single();
      const layoutPanels = layoutRow?.layout_data?.panels as PanelLayout[] | undefined;
      let compositeUrl: string | null = null;
      if (layoutPanels && layoutPanels.length > 0) {
        compositeUrl = await compositePlanchePage(supabase, planche.id, allPanels, layoutPanels, style);
      }
      const updateData: Record<string, any> = { status: "completed" };
      if (compositeUrl) {
        updateData.image_url = compositeUrl;
        updateData.metadata = { ...(planche.metadata ?? {}), composite: { width: COMPOSITE_W, height: COMPOSITE_H } };
      }
      await supabase.from("ai_planches").update(updateData).eq("id", planche.id);
    } else {
      await supabase.from("ai_planches").update({ status: "failed" }).eq("id", planche.id);
    }
  }
}

async function generatePoseForPanel(supabase: any, panel: any, plancheId: string): Promise<string | null> {
  const poseKey = panel.metadata?.pose_description || "neutral-stand";
  const kps = POSES[poseKey] || POSES["neutral-stand"];
  const png = renderSkeleton(kps);
  const fileName = `poses/${plancheId}/${panel.panel_index}.png`;

  // Upload to Supabase Storage
  try {
    const { data, error } = await supabase.storage
      .from("planche-assets")
      .upload(fileName, png, { contentType: "image/png", upsert: true });

    if (!error && data) {
      const { data: { publicUrl } } = supabase.storage
        .from("planche-assets")
        .getPublicUrl(fileName);
      return publicUrl;
    }
  } catch {
    // fallback to data URI
  }

  // Fallback: embed as base64 data URI
  const b64 = btoa(String.fromCharCode(...png));
  return `data:image/png;base64,${b64}`;
}

function selectBestRefForPanel(panel: any, charList: Character[], charRefMap: Record<string, Record<string, string>>): string | null {
  if (Object.keys(charRefMap).length === 0) return null;

  // Find which character is in this panel
  const panelChars = (panel.scene_description || "").toLowerCase() + " " + (panel.metadata?.pose_description || "");
  let targetChar = charList.find((c) => panelChars.includes(c.name.toLowerCase()));
  if (!targetChar) targetChar = charList[0];
  if (!targetChar || !charRefMap[targetChar.name]) return null;

  const refs = charRefMap[targetChar.name];
  const camAngle = panel.metadata?.camera_angle || "eye-level";

  // Map camera angle to best reference view
  const angleToView: Record<string, string> = {
    "eye-level": "front",
    "high-angle": "front",
    "low-angle": "front",
    "bird": "front",
    "worm": "front",
  };

  // If panel has a profile-like pose, use profile ref
  const profilePoses = ["action-punch", "action-point", "action-duel", "action-defend"];
  if (profilePoses.some((p) => (panel.metadata?.pose_description || "").includes(p))) {
    angleToView["eye-level"] = "three_quarter";
  }

  const bestView = angleToView[camAngle] || "front";
  return refs[bestView] || refs["front"] || null;
}

async function generateCharacterRefs(ch: Character, style: any): Promise<Record<string, string> | null> {
  if (!REPLICATE_API_KEY) return null;

  const qualityTags = "masterpiece, best quality, absurdres, highres";
  const basePrompt = `${qualityTags}, ${
    style.prompt_template.replace("{prompt}", `portrait of ${ch.name}, ${ch.appearance}`)
  }, manga character portrait, clean lineart, neutral expression, bust up, highly detailed face, distinct facial features, recognizable character design, consistent features`;

  const views: [string, string][] = [
    ["front", "front facing, symmetrical, looking at viewer"],
    ["three_quarter", "three-quarter view, slightly turned, looking forward"],
    ["profile", "profile view, side facing, looking to the side"],
  ];

  const result: Record<string, string> = {};
  for (const [viewName, viewDesc] of views) {
    const prompt = `${basePrompt}, ${viewDesc}`;
    const input: Record<string, any> = {
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

    if (!res.ok) continue;
    const prediction = await res.json();
    const url = await pollReplicate(prediction.id, `${ch.name}-${viewName}`);
    if (url) result[viewName] = url;
  }

  return Object.keys(result).length > 0 ? result : null;
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

    const poseKeys = Object.keys(POSES).join(", ");

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
- pose_description : choisir PARMI cette liste exacte (la plus proche de l'action) : ${poseKeys}

Retourne UNIQUEMENT un JSON array valide. Exemple :
[
  {"panel_index":0,"scene":"...","characters":"...","dialogue":"","narration":"","framing":"wide","camera_angle":"high-angle","emotion":"mélancolie","action":"...","pose_description":"neutral-stand"},
  ...
]`;

    const userPrompt = `SCÈNE À DÉCOUPER : ${scene}

${charSection}

NOMBRE DE CASES : ${panelCount}

Génère un découpage narratif professionnel avec progression dramatique.
Chaque case doit avoir un pose_description valide parmi : ${poseKeys}`;

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
      pose_description: "neutral-stand",
    });
  }
  return result;
}

function buildPanelPrompt(script: PanelScript, style: any, characters: Character[]): string {
  let prompt = style.prompt_template.replace("{prompt}", script.scene);

  // Character consistency: inject detailed appearance + name identity
  if (script.characters) {
    prompt += `, featuring ${script.characters}, consistent character design`;
  } else if (characters.length > 0) {
    const names = characters.map((c) => `${c.name}: ${c.appearance}, consistent ${c.name} design`).join(", ");
    prompt += `, featuring ${names}`;
  }

  // Add panel-specific character detail if a single character is named in scene
  if (script.characters && characters.length > 0) {
    for (const ch of characters) {
      if (script.characters.toLowerCase().includes(ch.name.toLowerCase())) {
        prompt += `, ${ch.name} portrayed with consistent facial features: ${ch.appearance}`;
        break;
      }
    }
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

async function generateSdxlImage(prompt: string, style: any, refImageUrl: string | null, poseImageUrl: string | null = null): Promise<string | null> {
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

  if (poseImageUrl) {
    input.controlnet_units = [{
      controlnet_model: "thibaud/controlnet-openpose-sdxl-1.0",
      controlnet_image: poseImageUrl,
      controlnet_weight: 0.8,
    }];
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

// ============================================================
// PHASE 4: POST-PROCESSING — Compositing & Upscaling
// ============================================================

const COMPOSITE_W = 2400;
const COMPOSITE_H = 3400;
const BORDER_PX = 3;

async function pngDecode(buf: ArrayBuffer): Promise<{width: number; height: number; rgba: Uint8Array}> {
  const b = new Uint8Array(buf);
  const sig = [137,80,78,71,13,10,26,10];
  for (let i = 0; i < 8; i++) if (b[i] !== sig[i]) throw new Error("Not a PNG");
  const r32 = (o: number) => (b[o]<<24)|(b[o+1]<<16)|(b[o+2]<<8)|b[o+3];
  let pos = 8, width = 0, height = 0, colorType = 0;
  let idat: Uint8Array | null = null;
  while (pos < b.length) {
    const len = r32(pos);
    const type = String.fromCharCode(b[pos+4],b[pos+5],b[pos+6],b[pos+7]);
    const data = b.slice(pos+8, pos+8+len);
    if (type === "IHDR") { width = r32(pos+8); height = r32(pos+12); colorType = data[9]; }
    else if (type === "IDAT") { idat = idat ? new Uint8Array([...idat, ...data]) : data.slice(); }
    else if (type === "IEND") break;
    pos += 12 + len;
  }
  if (!idat || !width || !height) throw new Error("Invalid PNG data");
  const ds = new DecompressionStream("deflate");
  const writer = ds.writable.getWriter();
  await writer.write(idat);
  await writer.close();
  const reader = ds.readable.getReader();
  const chunks: Uint8Array[] = [];
  while (true) { const {done,value} = await reader.read(); if (done) break; chunks.push(value); }
  const raw = new Uint8Array(chunks.reduce((s,c) => s + c.length, 0));
  let off = 0; for (const c of chunks) { raw.set(c, off); off += c.length; }
  const chMap = [1,0,3,1,2,0,4];
  const ch = chMap[colorType];
  if (!ch) throw new Error(`Unsupported color type ${colorType}`);
  const stride = ch * width;
  const rgba = new Uint8Array(width * height * 4);
  const prev = new Uint8Array(stride);
  const cur = new Uint8Array(stride);
  for (let y = 0; y < height; y++) {
    const ft = raw[y * (1 + stride)];
    const base = y * (1 + stride) + 1;
    for (let x = 0; x < stride; x++) cur[x] = raw[base + x];
    for (let x = 0; x < stride; x++) {
      let v = cur[x];
      if (ft === 1) v = (v + (x >= ch ? cur[x-ch] : 0)) & 0xFF;
      else if (ft === 2) v = (v + prev[x]) & 0xFF;
      else if (ft === 3) v = (v + Math.floor(((x >= ch ? cur[x-ch] : 0) + prev[x]) / 2)) & 0xFF;
      else if (ft === 4) {
        const a = x >= ch ? cur[x-ch] : 0, b2 = prev[x], c = x >= ch ? prev[x-ch] : 0;
        const p = a + b2 - c;
        const pa = Math.abs(p-a), pb = Math.abs(p-b2), pc = Math.abs(p-c);
        v = (v + (pa <= pb && pa <= pc ? a : pb <= pc ? b2 : c)) & 0xFF;
      }
      cur[x] = v;
    }
    for (let x = 0; x < width; x++) {
      const d = (y * width + x) * 4, s = x * ch;
      if (colorType === 2) { rgba[d]=cur[s];rgba[d+1]=cur[s+1];rgba[d+2]=cur[s+2];rgba[d+3]=255; }
      else if (colorType === 6) { rgba[d]=cur[s];rgba[d+1]=cur[s+1];rgba[d+2]=cur[s+2];rgba[d+3]=cur[s+3]; }
      else if (colorType === 0) { rgba[d]=cur[s];rgba[d+1]=cur[s];rgba[d+2]=cur[s];rgba[d+3]=255; }
      else if (colorType === 4) { rgba[d]=cur[s];rgba[d+1]=cur[s];rgba[d+2]=cur[s];rgba[d+3]=cur[s+1]; }
    }
    prev.set(cur);
  }
  return { width, height, rgba };
}

function bilinearResize(src: Uint8Array, sw: number, sh: number, dw: number, dh: number): Uint8Array {
  const dst = new Uint8Array(dw * dh * 4);
  for (let dy = 0; dy < dh; dy++) {
    for (let dx = 0; dx < dw; dx++) {
      const sx = (dx + 0.5) * sw / dw - 0.5, sy = (dy + 0.5) * sh / dh - 0.5;
      const x1 = Math.max(0, Math.floor(sx)), y1 = Math.max(0, Math.floor(sy));
      const x2 = Math.min(sw - 1, x1 + 1), y2 = Math.min(sh - 1, y1 + 1);
      const xf = sx - x1, yf = sy - y1;
      for (let c = 0; c < 4; c++) {
        const tl = src[(y1 * sw + x1) * 4 + c], tr = src[(y1 * sw + x2) * 4 + c];
        const bl = src[(y2 * sw + x1) * 4 + c], br = src[(y2 * sw + x2) * 4 + c];
        const t = tl + (tr - tl) * xf, b2 = bl + (br - bl) * xf;
        dst[(dy * dw + dx) * 4 + c] = Math.round(t + (b2 - t) * yf);
      }
    }
  }
  return dst;
}

async function compositePlanchePage(
  supabase: any, plancheId: string, panels: any[], layoutPanels: PanelLayout[], style: any
): Promise<string | null> {
  const scaleX = COMPOSITE_W / 100, scaleY = COMPOSITE_H / 100;
  const page = new Uint8Array(COMPOSITE_W * COMPOSITE_H * 4);
  for (let i = 0; i < page.length; i += 4) { page[i] = 255; page[i+1] = 255; page[i+2] = 255; page[i+3] = 255; }
  for (let i = 0; i < panels.length; i++) {
    const p = panels[i];
    if (!p.image_url || p.status !== "completed") continue;
    const l = layoutPanels[i];
    if (!l) continue;
    let imgBuf: ArrayBuffer;
    try { imgBuf = await (await fetch(p.image_url)).arrayBuffer(); } catch { continue; }
    let srcRgba: Uint8Array, srcW: number, srcH: number;
    try { const dec = await pngDecode(imgBuf); srcRgba = dec.rgba; srcW = dec.width; srcH = dec.height; } catch { continue; }
    const cellX = Math.round(l.x * scaleX);
    const cellY = Math.round(l.y * scaleY);
    const cellW = Math.round(l.w * scaleX);
    const cellH = Math.round(l.h * scaleY);
    if (cellW <= BORDER_PX*2 || cellH <= BORDER_PX*2) continue;
    const drawW = cellW - BORDER_PX * 2;
    const drawH = cellH - BORDER_PX * 2;
    const scaled = bilinearResize(srcRgba, srcW, srcH, drawW, drawH);
    for (let y = 0; y < drawH; y++) {
      const rowOff = (cellY + BORDER_PX + y) * COMPOSITE_W + cellX + BORDER_PX;
      for (let x = 0; x < drawW; x++) {
        const si = (y * drawW + x) * 4;
        const di = (rowOff + x) * 4;
        if (scaled[si+3] > 0) { page[di]=scaled[si];page[di+1]=scaled[si+1];page[di+2]=scaled[si+2];page[di+3]=255; }
      }
    }
    for (let by = 0; by < BORDER_PX; by++) {
      for (let bx = cellX; bx < cellX + cellW; bx++) {
        let di = ((cellY + by) * COMPOSITE_W + bx) * 4;
        page[di]=0;page[di+1]=0;page[di+2]=0;page[di+3]=255;
        di = ((cellY + cellH - 1 - by) * COMPOSITE_W + bx) * 4;
        page[di]=0;page[di+1]=0;page[di+2]=0;page[di+3]=255;
      }
    }
    for (let by = 0; by < BORDER_PX; by++) {
      for (let bx = cellY; bx < cellY + cellH; bx++) {
        let di = (bx * COMPOSITE_W + (cellX + by)) * 4;
        page[di]=0;page[di+1]=0;page[di+2]=0;page[di+3]=255;
        di = (bx * COMPOSITE_W + (cellX + cellW - 1 - by)) * 4;
        page[di]=0;page[di+1]=0;page[di+2]=0;page[di+3]=255;
      }
    }
  }
  const png = pngEncode(COMPOSITE_W, COMPOSITE_H, page);
  const fileName = `composites/${plancheId}.png`;
  try {
    const { data, error } = await supabase.storage.from("planche-assets").upload(fileName, png, { contentType: "image/png", upsert: true });
    if (!error && data) {
      const { data: { publicUrl } } = supabase.storage.from("planche-assets").getPublicUrl(fileName);
      return publicUrl;
    }
  } catch {}
  return null;
}

const UPSCALER = { owner: "nightmareai", name: "real-esrgan", version: "42a4a07ad14e8b0b2b3b0c2a3e5c5c0a8d0f1e2a3b4c5d6e7f8a9b0c1d2e3f" };

async function upscaleImage(imageUrl: string): Promise<string | null> {
  if (!REPLICATE_API_KEY) return null;
  const res = await fetch(`https://api.replicate.com/v1/models/${UPSCALER.owner}/${UPSCALER.name}/predictions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${REPLICATE_API_KEY}` },
    body: JSON.stringify({ version: UPSCALER.version, input: { image: imageUrl, scale: 2, face_enhance: false } }),
  });
  if (!res.ok) return null;
  const pred = await res.json();
  return pollReplicate(pred.id, "upscale");
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
