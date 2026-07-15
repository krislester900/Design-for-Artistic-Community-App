// Assemblage final de la planche (page simple + double page) + upscale.
// Utilise les modules image/effects/replicate.

import { makeLogger } from "../logger.ts";
import { PanelLayout } from "../types.ts";
import { upscaleImage } from "../replicate.ts";
import {
  COMPOSITE_W, COMPOSITE_H, pngEncode, pngDecode, bilinearResize,
  renderTextOnPage, textWidth, textHeight, drawMangaSpeechBubble, renderPanelNumber, FONT_W,
} from "./image.ts";
import {
  applyLineartCleanup, applyScreentoneRegion, getScreentoneForEmotion,
  applySmearEffects, drawFlowLines, drawImpactBurst, renderSFX,
  detectAdjacentPanels, applyGutterTransition, SFX_MAP,
} from "./effects.ts";

export const SPREAD_W = 4800;
export const SPREAD_H = 3400;

export async function compositePlanchePage(
  supabase: any, plancheId: string, panels: any[], layoutPanels: PanelLayout[], style: any, gutter: number = 3, pageNumber: number = 1
): Promise<string | null> {
  const log = makeLogger("compositePlanchePage", supabase);
  log.info(`Composition planche ${plancheId} — ${panels.length} panels`, { planche_id: plancheId, panel_count: panels.length, style_slug: style?.slug });
  const scaleX = COMPOSITE_W / 100, scaleY = COMPOSITE_H / 100;
  const page = new Uint8Array(COMPOSITE_W * COMPOSITE_H * 4).fill(255);

  // First pass: draw all panel images
  for (let i = 0; i < panels.length; i++) {
    const p = panels[i];
    if (!p.image_url || p.status !== "completed") continue;
    const l = layoutPanels[i];
    if (!l) continue;
    let imgBuf: ArrayBuffer;
    try { imgBuf = await (await fetch(p.image_url)).arrayBuffer(); } catch { continue; }
    let srcRgba: Uint8Array, srcW: number, srcH: number;
    try { const dec = await pngDecode(imgBuf); srcRgba = dec.rgba; srcW = dec.width; srcH = dec.height; } catch { continue; }

    // Detect break-frame : action intense + angle dynamique
    const poseKey = p.metadata?.pose_description || "";
    const camAngle = p.metadata?.camera_angle || "";
    const isBreakFrame = l.breakFrame === true || (
      (poseKey.includes("punch") || poseKey.includes("clash") || poseKey.includes("slash") || poseKey.includes("kick")) &&
      (camAngle === "worm" || camAngle === "low-angle")
    );

    const cellX = Math.round(l.x * scaleX);
    const cellY = Math.round(l.y * scaleY);
    const cellW = Math.round(l.w * scaleX);
    const cellH = Math.round(l.h * scaleY);
    if (cellW <= gutter*2 || cellH <= gutter*2) continue;

    if (isBreakFrame) {
      // Draw 12% oversized, centered, no border
      const overW = Math.round(cellW * 1.12);
      const overH = Math.round(cellH * 1.12);
      const drawX2 = cellX + Math.round((cellW - overW) / 2);
      const drawY2 = cellY + Math.round((cellH - overH) / 2);
      const overScaled = bilinearResize(srcRgba, srcW, srcH, overW, overH);
      for (let y = 0; y < overH; y++) {
        const rowOff = (drawY2 + y) * COMPOSITE_W + drawX2;
        for (let x = 0; x < overW; x++) {
          const si = (y * overW + x) * 4;
          const di = (rowOff + x) * 4;
          if (di >= 0 && di + 3 < page.length && overScaled[si+3] > 0) {
            page[di]=overScaled[si];page[di+1]=overScaled[si+1];page[di+2]=overScaled[si+2];page[di+3]=255;
          }
        }
      }
    } else {
      // Normal rendering with gutter
      const drawW = cellW - gutter * 2;
      const drawH = cellH - gutter * 2;
      const scaled = bilinearResize(srcRgba, srcW, srcH, drawW, drawH);
      for (let y = 0; y < drawH; y++) {
        const rowOff = (cellY + gutter + y) * COMPOSITE_W + cellX + gutter;
        for (let x = 0; x < drawW; x++) {
          const si = (y * drawW + x) * 4;
          const di = (rowOff + x) * 4;
          if (scaled[si+3] > 0) { page[di]=scaled[si];page[di+1]=scaled[si+1];page[di+2]=scaled[si+2];page[di+3]=255; }
        }
      }
      // Draw black borders
      for (let by = 0; by < gutter; by++) {
        for (let bx = cellX; bx < cellX + cellW; bx++) {
          let di = ((cellY + by) * COMPOSITE_W + bx) * 4;
          page[di]=0;page[di+1]=0;page[di+2]=0;page[di+3]=255;
          di = ((cellY + cellH - 1 - by) * COMPOSITE_W + bx) * 4;
          page[di]=0;page[di+1]=0;page[di+2]=0;page[di+3]=255;
        }
      }
      for (let by = 0; by < gutter; by++) {
        for (let bx = cellY; bx < cellY + cellH; bx++) {
          let di = (bx * COMPOSITE_W + (cellX + by)) * 4;
          page[di]=0;page[di+1]=0;page[di+2]=0;page[di+3]=255;
          di = (bx * COMPOSITE_W + (cellX + cellW - 1 - by)) * 4;
          page[di]=0;page[di+1]=0;page[di+2]=0;page[di+3]=255;
        }
      }
    }
  }

  // Step 5: Apply post-processing pipeline — lineart cleanup → transitions → per-panel screentone → speech bubbles → SFX → numbering
  let processed = applyLineartCleanup(page, COMPOSITE_W, COMPOSITE_H);

  // Cinematic transitions between adjacent panels
  if (layoutPanels.length >= 2) {
    const adjPairs = detectAdjacentPanels(layoutPanels, gutter);
    for (const pair of adjPairs) {
      const emA = panels[pair.a]?.metadata?.emotion || (panels[pair.a] as any)?.emotion || "";
      const emB = panels[pair.b]?.metadata?.emotion || (panels[pair.b] as any)?.emotion || "";
      applyGutterTransition(processed, COMPOSITE_W, COMPOSITE_H, pair, layoutPanels, emA, emB);
    }
  }

  // Per-panel screentone based on emotion
  for (let i = 0; i < panels.length; i++) {
    const p = panels[i];
    const l = layoutPanels[i];
    if (!l) continue;
    const emotion = p.metadata?.emotion || "";
    const st = getScreentoneForEmotion(emotion);
    const cellX = Math.round(l.x * scaleX);
    const cellY = Math.round(l.y * scaleY);
    const cellW = Math.round(l.w * scaleX);
    const cellH = Math.round(l.h * scaleY);
    // Skip gutters: shrink region by gutter/2
    const gHalf = Math.round(gutter / 2);
    processed = applyScreentoneRegion(processed, COMPOSITE_W, COMPOSITE_H,
      cellX + gHalf, cellY + gHalf, cellW - gutter, cellH - gutter,
      st.density, st.angle, st.type);
  }

  // Draw speech bubbles for panels with dialogue
  for (let i = 0; i < panels.length; i++) {
    const p = panels[i];
    if (!p.dialogue) continue;
    const l = layoutPanels[i];
    if (!l) continue;
    const cellX = Math.round(l.x * scaleX);
    const cellY = Math.round(l.y * scaleY);
    const cellW = Math.round(l.w * scaleX);
    const cellH = Math.round(l.h * scaleY);
    const pad = 16;
    const textScale = Math.max(1, Math.floor(cellH / 40));
    const maxCharsPerLine = Math.max(1, Math.floor((cellW - 32) / (FONT_W * textScale)));
    const dialogue = p.dialogue;
    const words = dialogue.split(/\s+/);
    const lines: string[] = [];
    let curLine = "";
    for (const w of words) {
      const candidate = curLine.length === 0 ? w : curLine + " " + w;
      if (candidate.length > maxCharsPerLine && curLine.length > 0) {
        lines.push(curLine.trim());
        curLine = w;
      } else {
        curLine = candidate;
      }
    }
    if (curLine.trim().length > 0) lines.push(curLine.trim());
    const lineH = textHeight(textScale);
    const textBlockH = lines.length * lineH + (lines.length - 1) * 4;
    const bubbleW = Math.min(cellW - pad * 2, Math.max(120, ...lines.map((ln) => textWidth(ln, textScale))) + 20);
    const bubbleH = Math.max(textBlockH + pad * 2, 40);
    const bubbleX = cellX + (cellW - bubbleW) / 2;
    const bubbleY = cellY + pad;
    drawMangaSpeechBubble(processed, COMPOSITE_W, COMPOSITE_H,
      bubbleX, bubbleY, bubbleW, bubbleH, "", "bottom", textScale);
    const startY = bubbleY + (bubbleH - textBlockH) / 2;
    for (let li = 0; li < lines.length; li++) {
      const lineW = textWidth(lines[li], textScale);
      const lineX = bubbleX + (bubbleW - lineW) / 2;
      renderTextOnPage(processed, COMPOSITE_W, COMPOSITE_H, lines[li],
        lineX, startY + li * (lineH + 4), textScale, 0, 255);
    }
  }

  // Apply dynamic effects + SFX for action panels
  const actionPoses = new Set(["punch", "kick", "leap", "spin-kick", "high-punch", "dodge", "ground-punch", "air-kick", "grab-thrust",
    "slash", "clash", "interact-punch-block", "interact-clash", "interact-throw"]);
  for (let i = 0; i < panels.length; i++) {
    const p = panels[i];
    const l = layoutPanels[i];
    if (!l) continue;
    const poseKey = p.metadata?.pose_description || "";
    if (![...actionPoses].some((ap) => poseKey.includes(ap))) continue;
    const cellX = Math.round(l.x * scaleX);
    const cellY = Math.round(l.y * scaleY);
    const cellW = Math.round(l.w * scaleX);
    const cellH = Math.round(l.h * scaleY);
    const burstCx = cellX + cellW / 2;
    const burstCy = cellY + cellH / 2;
    // Smear / motion blur (applied to processed buffer, affects underlying pixels)
    processed = applySmearEffects(processed, COMPOSITE_W, COMPOSITE_H, p, cellX, cellY, cellW, cellH);

    // Flow lines
    if (poseKey.includes("punch") || poseKey.includes("kick") || poseKey.includes("slash") || poseKey.includes("clash")) {
      const pageCx = COMPOSITE_W / 2, pageCy = COMPOSITE_H / 2;
      const flowEndX = burstCx + (burstCx - pageCx) * 0.6;
      const flowEndY = burstCy + (burstCy - pageCy) * 0.5;
      drawFlowLines(processed, COMPOSITE_W, COMPOSITE_H, burstCx, burstCy, flowEndX, flowEndY, 0.35);
    }
    // Impact burst
    if (poseKey.includes("clash") || poseKey.includes("impact") || poseKey.includes("throw")) {
      drawImpactBurst(processed, COMPOSITE_W, COMPOSITE_H, burstCx, burstCy, 60);
    }
    // SFX onomatopée
    const sfxWord = SFX_MAP[Object.keys(SFX_MAP).find(k => poseKey.includes(k)) || ""];
    if (sfxWord) {
      const sfxScale = Math.max(6, Math.min(14, Math.round(cellW / 20)));
      // Place SFX above the action center
      const sfxCy = Math.max(cellY + 20, burstCy - cellH * 0.15);
      const isInverted = p.metadata?.camera_angle === "worm" || p.metadata?.camera_angle === "low-angle";
      renderSFX(processed, COMPOSITE_W, COMPOSITE_H, sfxWord, burstCx, sfxCy, sfxScale, isInverted);
    }
  }

  // Numbering
  for (let i = 0; i < panels.length; i++) {
    const l = layoutPanels[i];
    if (!l) continue;
    const cellX = Math.round(l.x * scaleX);
    const cellY = Math.round(l.y * scaleY);
    const cellW = Math.round(l.w * scaleX);
    const numScale = Math.max(2, Math.min(5, Math.round(cellW / 60)));
    renderPanelNumber(processed, COMPOSITE_W, COMPOSITE_H, i + 1,
      cellX + numScale * 4, cellY + numScale * 4, numScale);
  }
  // Page number
  const pageNumText = plancheId.slice(0, 6) === "PAGE " ? plancheId.slice(5) : "";
  if (pageNumText || true) {
    // Draw page number at bottom-right
    const pgScale = 4;
    const pgText = `P.${plancheId.slice(0, 4)}`;
    const pgTw = textWidth(pgText, pgScale);
    const pgTh = textHeight(pgScale);
    const pgX = COMPOSITE_W - pgTw - 16;
    const pgY = COMPOSITE_H - pgTh - 8;
    // Black background box
    for (let dy = -2; dy <= pgTh + 2; dy++) {
      for (let dx = -2; dx <= pgTw + 2; dx++) {
        const x = pgX + dx, y = pgY + dy;
        if (x < 0 || x >= COMPOSITE_W || y < 0 || y >= COMPOSITE_H) continue;
        const i = (y * COMPOSITE_W + x) * 4;
        page[i] = 0; page[i+1] = 0; page[i+2] = 0; page[i+3] = 255;
      }
    }
    renderTextOnPage(processed, COMPOSITE_W, COMPOSITE_H, pgText, pgX + 2, pgY + 2, pgScale, 255, 0);
  }

  const png = pngEncode(COMPOSITE_W, COMPOSITE_H, processed);
  const fileName = `composites/${plancheId}.png`;
  try {
    const { data, error } = await supabase.storage.from("planche-assets").upload(fileName, png, { contentType: "image/png", upsert: true });
    if (!error && data) {
      const { data: { publicUrl } } = supabase.storage.from("planche-assets").getPublicUrl(fileName);
      log.info("Composite uploadé, upscale en cours", { planche_id: plancheId });

      // Step 6: Upscale the composite image
      const upscaledUrl = await upscaleImage(publicUrl);
      if (upscaledUrl) {
        const upscaledFileName = `composites/${plancheId}_upscaled.png`;
        try {
          const upscaledBuf = await (await fetch(upscaledUrl)).arrayBuffer();
          await supabase.storage.from("planche-assets").upload(upscaledFileName, new Uint8Array(upscaledBuf), { contentType: "image/png", upsert: true });
          const { data: { publicUrl: upscaledPublicUrl } } = supabase.storage.from("planche-assets").getPublicUrl(upscaledFileName);
          log.info("Composite upscalé terminé", { planche_id: plancheId });
          return upscaledPublicUrl;
        } catch {
          log.warn("Échec téléchargement upscaled, retour original", { planche_id: plancheId });
          return publicUrl;
        }
      }
      return publicUrl;
    }
  } catch {
    log.error("Échec upload composite", { planche_id: plancheId });
  }
  log.error("Composite abandonné — aucun résultat", { planche_id: plancheId });
  return null;
}

export async function compositeDoublePageSpread(supabase: any, plancheIds: string[],
  leftPanels: any[], rightPanels: any[], leftLayout: PanelLayout[], rightLayout: PanelLayout[],
  style: any, gutter: number = 3): Promise<string | null> {
  const scaleY = SPREAD_H / 100;
  const halfScaleX = (SPREAD_W / 2) / 100; // 24 — each half is 2400px
  const page = new Uint8Array(SPREAD_W * SPREAD_H * 4).fill(255);

  // Composite function for a set of panels (reused for both halves)
  async function compositeHalf(panels: any[], layout: PanelLayout[], offsetX: number): Promise<void> {
    for (let i = 0; i < panels.length; i++) {
      const p = panels[i];
      if (!p.image_url || p.status !== "completed") continue;
      const l = layout[i];
      if (!l) continue;
      let imgBuf: ArrayBuffer;
      try { imgBuf = await (await fetch(p.image_url)).arrayBuffer(); } catch { continue; }
      let srcRgba: Uint8Array, srcW: number, srcH: number;
      try { const dec = await pngDecode(imgBuf); srcRgba = dec.rgba; srcW = dec.width; srcH = dec.height; } catch { continue; }

      const cellX = Math.round(l.x * halfScaleX) + offsetX;
      const cellY = Math.round(l.y * scaleY);
      const cellW = Math.round(l.w * halfScaleX);
      const cellH = Math.round(l.h * scaleY);
      if (cellW <= gutter * 2 || cellH <= gutter * 2) continue;

      const drawW = cellW - gutter * 2;
      const drawH = cellH - gutter * 2;
      const scaled = bilinearResize(srcRgba, srcW, srcH, drawW, drawH);
      for (let y = 0; y < drawH; y++) {
        const rowOff = (cellY + gutter + y) * SPREAD_W + cellX + gutter;
        for (let x = 0; x < drawW; x++) {
          const si = (y * drawW + x) * 4;
          const di = (rowOff + x) * 4;
          if (scaled[si + 3] > 0) { page[di] = scaled[si]; page[di + 1] = scaled[si + 1]; page[di + 2] = scaled[si + 2]; page[di + 3] = 255; }
        }
      }
      // Gutters
      for (let by = 0; by < gutter; by++) {
        for (let bx = cellX; bx < cellX + cellW; bx++) {
          let di = ((cellY + by) * SPREAD_W + bx) * 4;
          page[di] = 0; page[di + 1] = 0; page[di + 2] = 0; page[di + 3] = 255;
          di = ((cellY + cellH - 1 - by) * SPREAD_W + bx) * 4;
          page[di] = 0; page[di + 1] = 0; page[di + 2] = 0; page[di + 3] = 255;
        }
      }
      for (let by = 0; by < gutter; by++) {
        for (let bx = cellY; bx < cellY + cellH; bx++) {
          let di = (bx * SPREAD_W + (cellX + by)) * 4;
          page[di] = 0; page[di + 1] = 0; page[di + 2] = 0; page[di + 3] = 255;
          di = (bx * SPREAD_W + (cellX + cellW - 1 - by)) * 4;
          page[di] = 0; page[di + 1] = 0; page[di + 2] = 0; page[di + 3] = 255;
        }
      }
    }
  }

  // Composite left half (offsetX = 0) and right half (offsetX = SPREAD_W/2)
  await compositeHalf(leftPanels, leftLayout, 0);
  await compositeHalf(rightPanels, rightLayout, SPREAD_W / 2);

  // Add center gutter (reliure)
  const centerX = SPREAD_W / 2;
  for (let gy = 0; gy < SPREAD_H; gy++) {
    for (let gx = centerX - gutter; gx < centerX + gutter; gx++) {
      const i = (gy * SPREAD_W + gx) * 4;
      page[i] = 0; page[i + 1] = 0; page[i + 2] = 0; page[i + 3] = 255;
    }
  }

  // Lineart cleanup
  const processed = applyLineartCleanup(page, SPREAD_W, SPREAD_H);

  // Transitions across the spread
  const allPanels = [...leftPanels, ...rightPanels];
  const allLayout = [...leftLayout, ...rightLayout.map(l => ({ ...l, x: l.x + 50 }))];
  if (allLayout.length >= 2) {
    const adjPairs = detectAdjacentPanels(allLayout, gutter);
    for (const pair of adjPairs) {
      const emA = allPanels[pair.a]?.metadata?.emotion || "";
      const emB = allPanels[pair.b]?.metadata?.emotion || "";
      // Reuse applyGutterTransition but scale coordinates from 100-based to pixel
      applyGutterTransition(processed, SPREAD_W, SPREAD_H, pair, allLayout, emA, emB);
    }
  }

  // Page numbers for spread (P.N / P.N+1)
  const pgText = `P.${plancheIds[0].slice(0, 4)}-${plancheIds[1].slice(0, 4)}`;
  const pgScale = 4;
  const pgTw = textWidth(pgText, pgScale);
  const pgTh = textHeight(pgScale);
  const pgX = SPREAD_W - pgTw - 16;
  const pgY = SPREAD_H - pgTh - 8;
  for (let dy = -2; dy <= pgTh + 2; dy++) {
    for (let dx = -2; dx <= pgTw + 2; dx++) {
      const x = pgX + dx, y = pgY + dy;
      if (x < 0 || x >= SPREAD_W || y < 0 || y >= SPREAD_H) continue;
      const i = (y * SPREAD_W + x) * 4;
      processed[i] = 0; processed[i + 1] = 0; processed[i + 2] = 0; processed[i + 3] = 255;
    }
  }
  renderTextOnPage(processed, SPREAD_W, SPREAD_H, pgText, pgX + 2, pgY + 2, pgScale, 255, 0);

  const png = pngEncode(SPREAD_W, SPREAD_H, processed);
  const spreadId = `${plancheIds[0]}_${plancheIds[1]}`;
  const fileName = `spreads/${spreadId}.png`;
  try {
    const { data, error } = await supabase.storage.from("planche-assets").upload(fileName, png, { contentType: "image/png", upsert: true });
    if (!error && data) {
      const { data: { publicUrl } } = supabase.storage.from("planche-assets").getPublicUrl(fileName);
      const upscaledUrl = await upscaleImage(publicUrl);
      if (upscaledUrl) {
        const upBuf = await (await fetch(upscaledUrl)).arrayBuffer();
        await supabase.storage.from("planche-assets").upload(`spreads/${spreadId}_upscaled.png`, new Uint8Array(upBuf), { contentType: "image/png", upsert: true });
      }
      return publicUrl;
    }
  } catch {}
  return null;
}
