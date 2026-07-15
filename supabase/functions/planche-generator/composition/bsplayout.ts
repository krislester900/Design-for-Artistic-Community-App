// Génération procédurale de layouts (BSP) + sélection finale.
import { PanelLayout } from "../types.ts";
import { LAYOUT_LIBRARY } from "./layouts.ts";

interface BSPNode { x: number; y: number; w: number; h: number; mood: string; }

export function generateBSPLayout(panelCount: number, moods: string[], pageW: number, pageH: number): PanelLayout[] {
  let leaves: BSPNode[] = [{ x: 0, y: 0, w: pageW, h: pageH, mood: moods[0] || "action" }];

  while (leaves.length < panelCount) {
    const idx = leaves.reduce((best, leaf, i) =>
      leaf.w * leaf.h > leaves[best].w * leaves[best].h ? i : best, 0);
    const leaf = leaves[idx];
    const mood = leaf.mood || "action";

    // Ensure final panels are large enough
    const minDim = Math.min(leaf.w, leaf.h);
    if (leaves.length === panelCount - 1) {
      // Don't split the last one further
      break;
    }
    // Don't split if would make panels too small
    const isAction = mood.includes("action") || mood.includes("climax") || mood.includes("fury");
    const minSize = isAction ? 18 : 22;
    if (minDim < minSize * 2) {
      // This leaf is too small to split, mark it and try next
      leaves[idx] = { ...leaf, mood };
      if (leaves.length >= panelCount) break;
      continue;
    }

    // Decide split direction: horizontal if wider, vertical if taller
    // For action, prefer vertical strips (dynamic)
    const splitH = isAction
      ? (leaf.w / leaf.h > 0.7 && Math.random() > 0.3)
      : leaf.w >= leaf.h;

    // Ratio: action likes uneven, calm likes equal
    let ratio = isAction ? (0.3 + Math.random() * 0.15) : (0.45 + Math.random() * 0.1);
    ratio = Math.max(0.22, Math.min(0.78, ratio));

    const nextMood = moods[leaves.length % moods.length];
    if (splitH) {
      const w1 = Math.round(leaf.w * ratio);
      leaves[idx] = { x: leaf.x, y: leaf.y, w: w1, h: leaf.h, mood };
      leaves.push({ x: leaf.x + w1, y: leaf.y, w: leaf.w - w1, h: leaf.h, mood: nextMood });
    } else {
      const h1 = Math.round(leaf.h * ratio);
      leaves[idx] = { x: leaf.x, y: leaf.y, w: leaf.w, h: h1, mood };
      leaves.push({ x: leaf.x, y: leaf.y + h1, w: leaf.w, h: leaf.h - h1, mood: nextMood });
    }
  }

  // Reading order: top-to-bottom, left-to-right (western digital), or right-to-left for manga
  // Manga: rightmost column first, top to bottom
  const sorted = [...leaves].sort((a, b) => {
    const colA = Math.round(a.x / 2), colB = Math.round(b.x / 2);
    return colB - colA || a.y - b.y;
  });

  return sorted.map((leaf, i) => ({
    x: leaf.x, y: leaf.y, w: leaf.w, h: leaf.h,
    label: `Case ${i + 1}`,
    breakFrame: (leaf.mood.includes("action") || leaf.mood.includes("climax")) && Math.random() > 0.6,
  }));
}

export function selectLayout(layoutSlug?: string, panelCount?: number, moods?: string[]): { panels: PanelLayout[]; slug: string; gutter: number } {
  const target = panelCount || 4;

  // Use BSP procedural generation unless explicit slug given
  if (!layoutSlug) {
    const moodArr = (moods && moods.length >= target) ? moods : moods || [];
    const bspPanels = generateBSPLayout(target, moodArr, 100, 100);
    return { panels: bspPanels, slug: `bsp-${target}`, gutter: 3 };
  }

  const found = LAYOUT_LIBRARY.find(l => l.slug === layoutSlug);
  if (found) return { panels: found.panels, slug: found.slug, gutter: found.gutter };

  const exact = LAYOUT_LIBRARY.filter(l => l.panels.length === target);
  if (exact.length > 0) {
    const chosen = exact[Math.floor(Math.random() * exact.length)];
    return { panels: chosen.panels, slug: chosen.slug, gutter: chosen.gutter };
  }

  const sorted = [...LAYOUT_LIBRARY].sort((a, b) =>
    Math.abs(a.panels.length - target) - Math.abs(b.panels.length - target));
  const fallback = sorted[0];
  return { panels: fallback.panels, slug: fallback.slug, gutter: fallback.gutter };
}
