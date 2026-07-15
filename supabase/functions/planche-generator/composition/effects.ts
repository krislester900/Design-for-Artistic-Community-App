// Post-processing manga : lineart cleanup, screentone, SFX, effets de mouvement,
// transitions entre cases, détection de cases adjacentes.
// Module pur (aucun effet de bord) → testable isolément.

import { PanelLayout, AdjacentPair } from "../types.ts";
import { COMPOSITE_W, COMPOSITE_H, textWidth, textHeight, renderTextOnPage, drawLine, drawThickLine } from "./image.ts";

export function drawFlowLines(rgba: Uint8Array, w: number, h: number,
  startX: number, startY: number, endX: number, endY: number,
  intensity: number = 0.3): void {
  const dirX = endX - startX, dirY = endY - startY;
  const len = Math.sqrt(dirX * dirX + dirY * dirY) || 1;
  const nx = -dirY / len, ny = dirX / len;
  const alpha = Math.round(180 * intensity);

  // 3 courbes de Bézier parallèles
  for (let lineN = -1; lineN <= 1; lineN++) {
    const offset = lineN * 5;
    const cpx = (startX + endX) / 2 + nx * offset + dirX * 0.3;
    const cpy = (startY + endY) / 2 + ny * offset + dirY * 0.3;
    const extX = endX + dirX * 0.5;
    const extY = endY + dirY * 0.5;

    const steps = Math.max(8, Math.round(len / 6));
    let prevX = startX, prevY = startY;
    const thickness = Math.max(3, Math.round(6 * (1 - Math.abs(lineN) * 0.3)));
    for (let t = 1; t <= steps; t++) {
      const u = t / steps;
      const bx = (1-u)*(1-u)*startX + 2*(1-u)*u*cpx + u*u*extX;
      const by = (1-u)*(1-u)*startY + 2*(1-u)*u*cpy + u*u*extY;
      const segAlpha = Math.round(alpha * (1 - 0.5 * u));
      drawThickLine(rgba, w, h, Math.round(prevX), Math.round(prevY),
        Math.round(bx), Math.round(by), 0, 0, 0, segAlpha, thickness);
      prevX = bx; prevY = by;
    }
  }
}

export function drawImpactBurst(rgba: Uint8Array, w: number, h: number, cx: number, cy: number, radius: number = 80): void {
  function setPx(x: number, y: number, r: number, g: number, b: number, a: number) {
    if (x < 0 || x >= w || y < 0 || y >= h) return;
    const i = (y * w + x) * 4;
    const blend = a / 255;
    rgba[i] = Math.round(rgba[i] * (1 - blend) + r * blend);
    rgba[i+1] = Math.round(rgba[i+1] * (1 - blend) + g * blend);
    rgba[i+2] = Math.round(rgba[i+2] * (1 - blend) + b * blend);
  }

  function burstLine(x1: number, y1: number, x2: number, y2: number, colR: number, colG: number, colB: number, a: number, thick: number = 1) {
    drawThickLine(rgba, w, h, x1, y1, x2, y2, colR, colG, colB, a, thick);
  }

  // 8 spokes avec épaisseur variable (plus épais au centre)
  for (let i = 0; i < 8; i++) {
    const angle = (i / 8) * Math.PI * 2;
    const outerR = radius + (Math.random() - 0.5) * 20; // irrégularité
    const x2 = Math.round(cx + Math.cos(angle) * outerR);
    const y2 = Math.round(cy + Math.sin(angle) * outerR);
    const innerR = radius * 0.25;
    const x1 = Math.round(cx + Math.cos(angle + 0.15) * innerR);
    const y1 = Math.round(cy + Math.sin(angle + 0.15) * innerR);
    burstLine(x1, y1, x2, y2, 0, 0, 0, 120, 3);
    // White highlight edge
    const x1h = Math.round(cx + Math.cos(angle - 0.15) * innerR);
    const y1h = Math.round(cy + Math.sin(angle - 0.15) * innerR);
    burstLine(x1h, y1h,
      Math.round(cx + Math.cos(angle) * outerR * 0.6),
      Math.round(cy + Math.sin(angle) * outerR * 0.6),
      255, 255, 255, 80, 2);
  }

  // Smear frame : halo d'étirement autour de l'impact
  for (let ring = 0; ring < 3; ring++) {
    const r = radius * (0.4 + ring * 0.15);
    const alphaRing = 30 - ring * 8;
    const stretch = 1 + ring * 0.3;
    for (let a = 0; a < 16; a++) {
      const aRad = (a / 16) * Math.PI * 2;
      const sx = Math.cos(aRad) * stretch, sy = Math.sin(aRad);
      const px = Math.round(cx + sx * r);
      const py = Math.round(cy + sy * r);
      if (px >= 0 && px < w && py >= 0 && py < h) {
        const i = (py * w + px) * 4;
        rgba[i] = Math.max(0, rgba[i] - alphaRing);
        rgba[i+1] = Math.max(0, rgba[i+1] - alphaRing);
        rgba[i+2] = Math.max(0, rgba[i+2] - alphaRing);
      }
    }
  }
}

// ============================================================
// POST-PROCESSING: Lineart cleanup (adaptive threshold)
// ============================================================
export function applyLineartCleanup(rgba: Uint8Array, w: number, h: number): Uint8Array {
  const out = new Uint8Array(rgba.length);
  const blurRadius = 8;
  const threshold = 48;

  // Compute integral image for fast local mean
  const integral = new Int32Array((w + 1) * (h + 1));
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4;
      const lum = (rgba[i] * 77 + rgba[i+1] * 150 + rgba[i+2] * 29) >> 8;
      integral[(y+1)*(w+1)+(x+1)] = lum + integral[y*(w+1)+(x+1)] + integral[(y+1)*(w+1)+x] - integral[y*(w+1)+x];
    }
  }

  function localMean(px: number, py: number): number {
    const x1 = Math.max(0, px - blurRadius), y1 = Math.max(0, py - blurRadius);
    const x2 = Math.min(w - 1, px + blurRadius), y2 = Math.min(h - 1, py + blurRadius);
    const area = (x2 - x1 + 1) * (y2 - y1 + 1);
    const sum = integral[(y2+1)*(w+1)+(x2+1)] - integral[y1*(w+1)+(x2+1)] - integral[(y2+1)*(w+1)+x1] + integral[y1*(w+1)+x1];
    return sum / area;
  }

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4;
      const lum = (rgba[i] * 77 + rgba[i+1] * 150 + rgba[i+2] * 29) >> 8;
      const mean = localMean(x, y);
      const val = (lum < mean - threshold) ? 0 : 255;
      out[i] = val; out[i+1] = val; out[i+2] = val; out[i+3] = 255;
    }
  }
  return out;
}

// ============================================================
// POST-PROCESSING: Screentone overlay (manga dot pattern)
// ============================================================
export function applyScreentone(rgba: Uint8Array, w: number, h: number, density: number = 0.15): Uint8Array {
  const out = new Uint8Array(rgba.length);
  const period = 12;
  const angle = Math.PI / 6;
  const cosA = Math.cos(angle), sinA = Math.sin(angle);

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4;
      // Get luminance from source
      const lum = (rgba[i] * 77 + rgba[i+1] * 150 + rgba[i+2] * 29) >> 8;
      out[i] = rgba[i]; out[i+1] = rgba[i+1]; out[i+2] = rgba[i+2]; out[i+3] = 255;

      // Rotate coordinates for screen angle
      const u = x * cosA + y * sinA;
      const v = -x * sinA + y * cosA;
      const du = ((u % period) + period) % period;
      const dv = ((v % period) + period) % period;
      const cx2 = period / 2, cy2 = period / 2;
      const dist = Math.sqrt((du - cx2) ** 2 + (dv - cy2) ** 2);
      const maxD = period / 2 + 1;
      const dotVal = Math.min(1, dist / maxD);

      // Dot area varies with luminance: darker -> larger dots
      const tone = Math.max(0, Math.min(255, lum));
      const dotRadius = Math.max(0, Math.min(1, 1 - tone / 255 - density));

      let outputLum: number;
      if (dotVal < dotRadius) {
        // Inside dot: ink (dark)
        outputLum = Math.max(0, tone - 40);
      } else {
        // Outside dot: paper (light)
        outputLum = Math.min(255, tone + 30);
      }

      // Blend with original using the halftone value
      const blend = 0.7;
      const finalLum = Math.round(lum * (1 - blend) + outputLum * blend);
      out[i] = finalLum; out[i+1] = finalLum; out[i+2] = finalLum;
    }
  }
  return out;
}

// ---------- Screentone par ambiance ----------
export function getScreentoneForEmotion(emotion: string): { type: string; density: number; angle: number } {
  const e = (emotion || "").toLowerCase();
  if (["calm","peace","romance","tenderness","melancholy","sad","tristesse"].some(k => e.includes(k)))
    return { type: "dot", density: 0.10, angle: Math.PI / 4 };
  if (["action","fury","anger","rage","combat","battle"].some(k => e.includes(k)))
    return { type: "dot", density: 0.25, angle: Math.PI / 5 };
  if (["horror","fear","tension","anxiety","dread","peur","angoisse"].some(k => e.includes(k)))
    return { type: "line", density: 0.30, angle: 0 };
  if (["flashback","memory","past","souvenir","nostalgia"].some(k => e.includes(k)))
    return { type: "dot", density: 0.06, angle: Math.PI / 3 };
  return { type: "dot", density: 0.18, angle: Math.PI / 6 };
}

export function applyScreentoneRegion(rgba: Uint8Array, w: number, h: number,
  rx: number, ry: number, rw: number, rh: number,
  density: number, angle: number, type: string): Uint8Array {
  const out = new Uint8Array(rgba.length);
  out.set(rgba);
  const period = type === "line" ? 8 : 12;
  const cosA = Math.cos(angle), sinA = Math.sin(angle);
  const x1 = Math.max(0, rx), y1 = Math.max(0, ry);
  const x2 = Math.min(w, rx + rw), y2 = Math.min(h, ry + rh);
  for (let y = y1; y < y2; y++) {
    for (let x = x1; x < x2; x++) {
      const i = (y * w + x) * 4;
      const lum = (rgba[i] * 77 + rgba[i+1] * 150 + rgba[i+2] * 29) >> 8;
      let dotVal: number;
      if (type === "line") {
        const proj = x * cosA + y * sinA;
        const band = ((proj % period) + period) % period;
        dotVal = band / period;
      } else {
        const u = x * cosA + y * sinA;
        const v = -x * sinA + y * cosA;
        const du = ((u % period) + period) % period;
        const dv = ((v % period) + period) % period;
        const dist = Math.sqrt((du - period/2) ** 2 + (dv - period/2) ** 2);
        dotVal = Math.min(1, dist / (period/2 + 1));
      }
      const tone = Math.max(0, Math.min(255, lum));
      const dotRadius = Math.max(0, Math.min(1, 1 - tone / 255 - density));
      const outputLum = dotVal < dotRadius
        ? Math.max(0, tone - 40)
        : Math.min(255, tone + 30);
      const blend = 0.7;
      const finalLum = Math.round(lum * (1 - blend) + outputLum * blend);
      out[i] = finalLum; out[i+1] = finalLum; out[i+2] = finalLum;
    }
  }
  return out;
}

// ---------- SFX (onomatopées) ----------
export const SFX_MAP: Record<string, string> = {
  "punch": "BAM!", "high-punch": "SMASH!", "kick": "WHAM!",
  "spin-kick": "CRACK!", "air-kick": "BAM!", "slash": "SWISH!",
  "clash": "CLANG!", "grab-thrust": "THUD!", "leap": "SOAR!",
  "ground-punch": "CRASH!", "dodge": "SWISH!", "throw": "FLING!",
  "power-up": "SURGE!", "punch-block": "SMASH!", "impact": "BOOM!",
};

export function renderSFX(page: Uint8Array, pw: number, ph: number, word: string,
  cx: number, cy: number, scale: number, inverted: boolean): void {
  const tw = textWidth(word, scale);
  const th = textHeight(scale);
  const px = Math.round(cx - tw / 2);
  const py = Math.round(cy - th / 2);
  const off = 2;
  for (let ox = -off; ox <= off; ox += off) {
    for (let oy = -off; oy <= off; oy += off) {
      renderTextOnPage(page, pw, ph, word, px + ox, py + oy, scale, inverted ? 255 : 0, 0);
    }
  }
  renderTextOnPage(page, pw, ph, word, px, py, scale, inverted ? 0 : 255, 0);
}

// ---------- Numérotation ----------
export function renderPanelNumber(page: Uint8Array, pw: number, ph: number,
  num: number, cx: number, cy: number, scale: number): void {
  const txt = String(num);
  const tw = textWidth(txt, scale);
  const th = textHeight(scale);
  const pad = scale * 2;
  const r = Math.max(tw, th) / 2 + pad;
  const px = Math.round(cx - tw / 2);
  const py = Math.round(cy - th / 2);
  for (let dy = -r; dy <= r; dy++) {
    for (let dx = -r; dx <= r; dx++) {
      if (dx*dx + dy*dy > r*r) continue;
      const x = Math.round(cx + dx);
      const y = Math.round(cy + dy);
      if (x < 0 || x >= pw || y < 0 || y >= ph) continue;
      const i = (y * pw + x) * 4;
      page[i]=0; page[i+1]=0; page[i+2]=0; page[i+3]=255;
    }
  }
  renderTextOnPage(page, pw, ph, txt, px, py, scale, 255, 0);
}

// ---------- Smear / Motion Blur post-processing ----------
export function applyMotionBlur(rgba: Uint8Array, w: number, h: number,
  cx: number, cy: number, angle: number, length: number, intensity: number,
  radius: number = 0): Uint8Array {
  const out = new Uint8Array(rgba.length);
  out.set(rgba);
  const dx = Math.cos(angle), dy = Math.sin(angle);
  const samples = Math.max(3, Math.round(length / 3));
  const maxR2 = radius > 0 ? radius * radius : Infinity;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      if (radius > 0) {
        const dr2 = (x - cx) ** 2 + (y - cy) ** 2;
        if (dr2 > maxR2) continue;
      }
      const i = (y * w + x) * 4;
      let r = 0, g = 0, b = 0, total = 0;
      for (let s = -samples; s <= samples; s++) {
        const sx = Math.round(x + dx * s * length / samples);
        const sy = Math.round(y + dy * s * length / samples);
        if (sx < 0 || sx >= w || sy < 0 || sy >= h) continue;
        const si = (sy * w + sx) * 4;
        const weight = 1 - Math.abs(s) / (samples + 1);
        r += rgba[si] * weight; g += rgba[si + 1] * weight;
        b += rgba[si + 2] * weight; total += weight;
      }
      if (total > 0) {
        const alpha = intensity;
        out[i] = Math.round(out[i] * (1 - alpha) + (r / total) * alpha);
        out[i + 1] = Math.round(out[i + 1] * (1 - alpha) + (g / total) * alpha);
        out[i + 2] = Math.round(out[i + 2] * (1 - alpha) + (b / total) * alpha);
      }
    }
  }
  return out;
}

export function applyZoomBlur(rgba: Uint8Array, w: number, h: number,
  cx: number, cy: number, intensity: number, radius: number): Uint8Array {
  const out = new Uint8Array(rgba.length);
  out.set(rgba);
  const maxR2 = radius * radius;
  const samples = 6;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const dx = x - cx, dy = y - cy;
      const r2 = dx * dx + dy * dy;
      if (r2 > maxR2 || r2 < 4) continue;
      const dist = Math.sqrt(r2);
      const nx = dx / dist, ny = dy / dist;
      const i = (y * w + x) * 4;
      let r = 0, g = 0, b = 0, total = 0;
      for (let s = 0; s < samples; s++) {
        const t = (s / samples) ** 0.6;
        const sx = Math.round(cx + nx * dist * (1 - t));
        const sy = Math.round(cy + ny * dist * (1 - t));
        if (sx < 0 || sx >= w || sy < 0 || sy >= h) continue;
        const si = (sy * w + sx) * 4;
        const weight = 1 - t;
        r += rgba[si] * weight; g += rgba[si + 1] * weight;
        b += rgba[si + 2] * weight; total += weight;
      }
      if (total > 0) {
        const alpha = intensity * (1 - dist / radius);
        out[i] = Math.round(out[i] * (1 - alpha) + (r / total) * alpha);
        out[i + 1] = Math.round(out[i + 1] * (1 - alpha) + (g / total) * alpha);
        out[i + 2] = Math.round(out[i + 2] * (1 - alpha) + (b / total) * alpha);
      }
    }
  }
  return out;
}

export function applySmearEffects(rgba: Uint8Array, w: number, h: number,
  panel: any, cellX: number, cellY: number, cellW: number, cellH: number): Uint8Array {
  const poseKey = panel.metadata?.pose_description || "";
  const cx = cellX + cellW / 2, cy = cellY + cellH / 2;
  let result = rgba;

  // Ghost trail for fast directional attacks
  if (poseKey.includes("punch") || poseKey.includes("slash") || poseKey.includes("kick") || poseKey.includes("high-punch")) {
    let angle = 0, length = 0;
    if (poseKey.includes("punch")) { angle = 0; length = 40; }
    else if (poseKey.includes("slash")) { angle = Math.PI / 6; length = 50; }
    else if (poseKey.includes("kick")) { angle = Math.PI / 3; length = 45; }
    else { angle = -Math.PI / 6; length = 35; }
    // Only blur the region around the attacking limb (lower half of cell)
    const limbCy = cy + cellH * 0.15;
    result = applyMotionBlur(result, w, h, cx, limbCy, angle, length, 0.45, cellW * 0.5);
  }

  // Zoom blur for clash/impact centers
  if (poseKey.includes("clash") || poseKey.includes("impact") || poseKey.includes("throw")) {
    result = applyZoomBlur(result, w, h, cx, cy, 0.5, Math.max(cellW, cellH) * 0.3);
  }

  return result;
}

// ---------- Transitions cinématiques entre cases adjacentes ----------
export function detectAdjacentPanels(panels: PanelLayout[], gutter: number): AdjacentPair[] {
  const pairs: AdjacentPair[] = [];
  const scaleX = COMPOSITE_W / 100, scaleY = COMPOSITE_H / 100;
  const gPx = Math.round(gutter * 2);

  for (let i = 0; i < panels.length; i++) {
    for (let j = i + 1; j < panels.length; j++) {
      const a = panels[i], b2 = panels[j];
      const ax1 = a.x * scaleX, ay1 = a.y * scaleY, ax2 = (a.x + a.w) * scaleX, ay2 = (a.y + a.h) * scaleY;
      const bx1 = b2.x * scaleX, by1 = b2.y * scaleY, bx2 = (b2.x + b2.w) * scaleX, by2 = (b2.y + b2.h) * scaleY;

      // Horizontal adjacency: a's right edge touches b's left edge
      const hOverlap = Math.max(0, Math.min(ay2, by2) - Math.max(ay1, by1));
      const hGap = Math.abs(ax2 - bx1);
      if (hOverlap > 20  && hGap <= gPx + 2) {
        const gx = Math.round(Math.min(ax2, bx1));
        const gy = Math.round(Math.max(ay1, by1));
        const gw = Math.round(hGap);
        const gh = Math.round(Math.min(ay2, by2) - Math.max(ay1, by1));
        pairs.push({ a: i, b: j, dir: "h", gutterX: gx, gutterY: gy, gutterW: gw, gutterH: gh });
        continue;
      }

      // Vertical adjacency: a's bottom edge touches b's top edge
      const vOverlap = Math.max(0, Math.min(ax2, bx2) - Math.max(ax1, bx1));
      const vGap = Math.abs(ay2 - by1);
      if (vOverlap > 20 && vGap <= gPx + 2) {
        const gx = Math.round(Math.max(ax1, bx1));
        const gy = Math.round(Math.min(ay2, by1));
        const gw = Math.round(Math.min(ax2, bx2) - Math.max(ax1, bx1));
        const gh = Math.round(vGap);
        pairs.push({ a: i, b: j, dir: "v", gutterX: gx, gutterY: gy, gutterW: gw, gutterH: gh });
      }
    }
  }
  return pairs;
}

export function applyGutterTransition(page: Uint8Array, w: number, h: number,
  pair: AdjacentPair, panels: PanelLayout[], emotionA: string, emotionB: string): void {
  const { gutterX, gutterY, gutterW, gutterH, dir } = pair;
  const isAction = emotionA.includes("action") || emotionB.includes("action") ||
    emotionA.includes("fury") || emotionB.includes("fury");
  const isFlashback = emotionA.includes("flashback") || emotionB.includes("flashback") ||
    emotionA.includes("memory") || emotionB.includes("memory");
  const isCalm = emotionA.includes("calm") || emotionB.includes("calm") ||
    emotionA.includes("peace") || emotionB.includes("peace");

  if (isAction) {
    // Speed cross: replace black gutter with converging speed lines
    const cx = gutterX + gutterW / 2, cy = gutterY + gutterH / 2;
    const steps = dir === "h" ? gutterW : gutterH;
    for (let t = 0; t < steps; t++) {
      const u = t / steps;
      const alpha = Math.round(40 * (1 - Math.abs(u - 0.5) * 1.5));
      const spread = Math.round(gutterH * 0.3 * (1 - Math.abs(u - 0.5)));
      if (dir === "h") {
        const x = gutterX + t;
        for (let s = -spread; s <= spread; s++) {
          const y = cy + s;
          if (x < 0 || x >= w || y < 0 || y >= h) continue;
          const i = (y * w + x) * 4;
          page[i] = 0; page[i+1] = 0; page[i+2] = 0; page[i+3] = Math.min(255, alpha + 60);
        }
      } else {
        const y = gutterY + t;
        for (let s = -spread; s <= spread; s++) {
          const x = cx + s;
          if (x < 0 || x >= w || y < 0 || y >= h) continue;
          const i = (y * w + x) * 4;
          page[i] = 0; page[i+1] = 0; page[i+2] = 0; page[i+3] = Math.min(255, alpha + 60);
        }
      }
    }
  } else if (isFlashback) {
    // White flash transition
    for (let y = gutterY; y < gutterY + gutterH; y++) {
      for (let x = gutterX; x < gutterX + gutterW; x++) {
        if (x < 0 || x >= w || y < 0 || y >= h) continue;
        const i = (y * w + x) * 4;
        const t = dir === "h" ? (x - gutterX) / gutterW : (y - gutterY) / gutterH;
        const alpha = Math.round(120 * (1 - Math.abs(t - 0.5) * 1.2));
        page[i] = 255; page[i+1] = 255; page[i+2] = 255; page[i+3] = Math.min(255, alpha + 60);
      }
    }
  } else {
    // Gradient transition: blend from left/top panel edge color to right/bottom
    const steps = dir === "h" ? gutterW : gutterH;
    for (let t = 0; t < steps; t++) {
      const u = t / steps;
      const alpha = Math.round(80 * (1 - Math.abs(u - 0.5) * 1.5));
      const gray = Math.round(60 + 135 * u);
      if (dir === "h") {
        const x = gutterX + t;
        for (let y = gutterY; y < gutterY + gutterH; y++) {
          if (x < 0 || x >= w || y < 0 || y >= h) continue;
          const i = (y * w + x) * 4;
          page[i] = gray; page[i+1] = gray; page[i+2] = gray; page[i+3] = Math.min(255, alpha + 40);
        }
      } else {
        const y = gutterY + t;
        for (let x = gutterX; x < gutterX + gutterW; x++) {
          if (x < 0 || x >= w || y < 0 || y >= h) continue;
          const i = (y * w + x) * 4;
          page[i] = gray; page[i+1] = gray; page[i+2] = gray; page[i+3] = Math.min(255, alpha + 40);
        }
      }
    }
  }
}
