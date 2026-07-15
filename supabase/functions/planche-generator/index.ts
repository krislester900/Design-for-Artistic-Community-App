import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { makeLogger } from "./logger.ts";
import { Character, PanelLayout, Poseless } from "./types.ts";
import { generateSdxlImage } from "./replicate.ts";
import { triggerTrainingWebhook } from "./github.ts";
import { POSES, applyForeshortening, mirrorPose, renderSkeleton } from "./composition/pose.ts";
import { generatePanelScripts, generateCharacterRefs, buildPanelPrompt } from "./composition/layout.ts";
import { selectLayout } from "./composition/bsplayout.ts";
import { compositePlanchePage, compositeDoublePageSpread, SPREAD_W, SPREAD_H } from "./composition/composite.ts";
import { COMPOSITE_W, COMPOSITE_H } from "./composition/image.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

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

  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
  const log = makeLogger("serve", supabase);
  const result = await handleCreate(req);
  if (result.status >= 400) {
    log.warn(`Requête POST échouée HTTP ${result.status}`, { path: url.pathname });
  }
  return result;
});

async function handleCreate(req: Request): Promise<Response> {
  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
  const log = makeLogger("handleCreate", supabase);
  try {
    const authHeader = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!authHeader) throw new Error("Non authentifié");

    const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader);
    if (authError || !user) throw new Error("Utilisateur non trouvé");

    const body = await req.json();
    const { scene, style_slug, characters, layout_type, panel_count, title, page_number, total_pages } = body;

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

    const { panels: layoutPanels, slug: layoutSlug, gutter: layoutGutter } = selectLayout(layout_type || undefined, panel_count);
    const layoutData = { panels: layoutPanels, slug: layoutSlug };

    const panelCount = layoutPanels.length;
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
      metadata: { panel_count: panelCount, char_ref_map: {}, gutter: layoutGutter },
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

    log.info("Planche créée", { planche_id: planche.id, style_slug, panel_count: panelCount });
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
    log.error("Erreur handleCreate", { error: msg });
    return new Response(JSON.stringify({ error: "Erreur interne" }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
}

async function handleGetStatus(plancheId: string): Promise<Response> {
  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
  const log = makeLogger("handleGetStatus", supabase);
  try {
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
    log.error("Erreur handleGetStatus", { planche_id: plancheId, error: msg });
    return new Response(JSON.stringify({ error: "Erreur interne" }), { status: 500, headers: { "Content-Type": "application/json" } });
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
      const { data: freshPlanche } = await supabase
        .from("ai_planches")
        .select("metadata")
        .eq("id", planche.id)
        .limit(1)
        .single();
      const currentMeta = freshPlanche?.metadata ?? planche.metadata ?? {};
      const gutter = currentMeta.gutter ?? 3;
      const pageNum = planche.page_number ?? 1;

      let layoutPanels: PanelLayout[] | undefined;
      const { data: layoutRow } = await supabase
        .from("ai_planche_layouts")
        .select("layout_data")
        .eq("slug", planche.layout_slug)
        .limit(1)
        .single();
      if (layoutRow?.layout_data?.panels) {
        layoutPanels = layoutRow.layout_data.panels as PanelLayout[];
      } else {
        const layout = selectLayout(planche.layout_slug);
        layoutPanels = layout.panels;
      }

      // Optional double-page spread: if planche has `spread_with` metadata referencing another planche ID
      let compositeUrl: string | null = null;
      const spreadWithId = currentMeta.spread_with as string | undefined;

      if (spreadWithId && layoutPanels) {
        const { data: rightPlanche } = await supabase
          .from("ai_planches")
          .select("id, layout_slug, metadata, page_number")
          .eq("id", spreadWithId)
          .limit(1)
          .maybeSingle();

        if (rightPlanche) {
          const { data: rightPanels } = await supabase
            .from("ai_planche_panels")
            .select("*")
            .eq("planche_id", rightPlanche.id)
            .order("panel_index");

          const rightMeta = rightPlanche.metadata ?? {};
          const rightGutter = rightMeta.gutter ?? gutter;

          let rightLayout: PanelLayout[] | undefined;
          const { data: rightLayoutRow } = await supabase
            .from("ai_planche_layouts")
            .select("layout_data")
            .eq("slug", rightPlanche.layout_slug)
            .limit(1)
            .single();
          if (rightLayoutRow?.layout_data?.panels) {
            rightLayout = rightLayoutRow.layout_data.panels as PanelLayout[];
          } else {
            const rl = selectLayout(rightPlanche.layout_slug);
            rightLayout = rl.panels;
          }

          if (rightPanels?.every((p: any) => p.status === "completed") && rightLayout) {
            compositeUrl = await compositeDoublePageSpread(supabase,
              [planche.id, rightPlanche.id], allPanels, rightPanels,
              layoutPanels, rightLayout, style, Math.min(gutter, rightGutter));

            if (compositeUrl) {
              await supabase.from("ai_planches").update({
                status: "completed", image_url: compositeUrl,
                metadata: { ...rightMeta, spread: true },
              }).eq("id", rightPlanche.id);
            }
          }
        }
      }

      if (!compositeUrl && layoutPanels && layoutPanels.length > 0) {
        compositeUrl = await compositePlanchePage(supabase, planche.id, allPanels, layoutPanels, style, gutter, pageNum);
      }

      const updateData: Record<string, any> = { status: "completed" };
      if (compositeUrl) {
        updateData.image_url = compositeUrl;
        updateData.metadata = { ...currentMeta, composite: { width: !!spreadWithId ? SPREAD_W : COMPOSITE_W, height: SPREAD_H } };

        // Improvement loop: add successful panel images as references for style training
        const panelUrls = allPanels
          ?.filter((p: any) => p.image_url && p.status === "completed")
          ?.slice(0, 8)
          ?.map((p: any) => p.image_url) ?? [];
        if (panelUrls.length > 0) {
          try {
            const trainerRes = await fetch(`${SUPABASE_URL}/functions/v1/manga-trainer`, {
              method: "POST",
              headers: { "Content-Type": "application/json", Authorization: `Bearer ${SUPABASE_KEY}` },
              body: JSON.stringify({
                action: "add_composite_refs",
                style_slug: planche.style_slug,
                image_urls: panelUrls,
              }),
            });
            if (trainerRes.ok) {
              const trainerData = await trainerRes.json();
              // If style just became "ready", trigger training workflow
              if (trainerData.ready) {
                await triggerTrainingWebhook(planche.style_slug);
              }
            }
          } catch { /* amélioration silencieuse */ }
        }

        // Increment generation_count (direct SQL increment via RPC or raw update)
        try {
          const { data: curStyle } = await supabase
            .from("ai_manga_styles")
            .select("generation_count")
            .eq("slug", planche.style_slug)
            .limit(1)
            .maybeSingle();
          await supabase.from("ai_manga_styles").update({
            generation_count: ((curStyle as any)?.generation_count ?? 0) + 1,
          }).eq("slug", planche.style_slug);
        } catch { /* silencieux */ }
      }
      await supabase.from("ai_planches").update(updateData).eq("id", planche.id);
    } else {
      await supabase.from("ai_planches").update({ status: "failed" }).eq("id", planche.id);
    }
  }
}

async function generatePoseForPanel(supabase: any, panel: any, plancheId: string): Promise<string | null> {
  const poseKey = panel.metadata?.pose_description || "neutral-stand";
  let kps: Poseless = (POSES[poseKey] || POSES["neutral-stand"]);
  // Apply foreshortening (segment-based perspective) + camera angle
  kps = applyForeshortening(kps, poseKey, panel.metadata?.camera_angle || "eye-level");
  // Mirror odd panels for variety
  if (panel.panel_index % 2 === 1 && kps.length === 18) {
    kps = mirrorPose(kps);
  }
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
