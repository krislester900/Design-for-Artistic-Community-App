// Bibliothèque de layouts pré-définis (fallback si pas de slug / BSP).
import { LayoutTemplate } from "../types.ts";

export const LAYOUT_LIBRARY: LayoutTemplate[] = [
  { slug: "4-equal", vibe: "calm", gutter: 3, panels: [
    { x: 0, y: 0, w: 50, h: 50, label: "Case 1" }, { x: 50, y: 0, w: 50, h: 50, label: "Case 2" },
    { x: 0, y: 50, w: 50, h: 50, label: "Case 3" }, { x: 50, y: 50, w: 50, h: 50, label: "Case 4" },
  ]},
  { slug: "4-story", vibe: "story", gutter: 4, panels: [
    { x: 0, y: 0, w: 100, h: 55, label: "Case 1" }, { x: 0, y: 55, w: 50, h: 22, label: "Case 2" },
    { x: 50, y: 55, w: 50, h: 22, label: "Case 3" }, { x: 0, y: 77, w: 100, h: 23, label: "Case 4" },
  ]},
  { slug: "4-action", vibe: "action", gutter: 3, panels: [
    { x: 0, y: 0, w: 55, h: 60, label: "Case 1" }, { x: 55, y: 0, w: 45, h: 35, label: "Case 2" },
    { x: 55, y: 35, w: 45, h: 25, label: "Case 3" }, { x: 0, y: 60, w: 100, h: 40, label: "Case 4" },
  ]},
  { slug: "4-climax", vibe: "climax", gutter: 6, panels: [
    { x: 0, y: 0, w: 100, h: 35, label: "Case 1" }, { x: 0, y: 35, w: 30, h: 30, label: "Case 2" },
    { x: 30, y: 35, w: 40, h: 30, label: "Case 3" }, { x: 70, y: 35, w: 30, h: 30, label: "Case 4" },
  ]},
  { slug: "4-drama", vibe: "drama", gutter: 5, panels: [
    { x: 0, y: 0, w: 50, h: 35, label: "Case 1" }, { x: 50, y: 0, w: 50, h: 35, label: "Case 2" },
    { x: 0, y: 35, w: 50, h: 65, label: "Case 3" }, { x: 50, y: 35, w: 50, h: 65, label: "Case 4" },
  ]},
  { slug: "4-vertical", vibe: "action", gutter: 3, panels: [
    { x: 0, y: 0, w: 100, h: 40, label: "Case 1" }, { x: 0, y: 40, w: 48, h: 30, label: "Case 2" },
    { x: 52, y: 40, w: 48, h: 30, label: "Case 3" }, { x: 0, y: 70, w: 100, h: 30, label: "Case 4" },
  ]},
  { slug: "5-story", vibe: "story", gutter: 4, panels: [
    { x: 0, y: 0, w: 100, h: 40, label: "Case 1" }, { x: 0, y: 40, w: 50, h: 30, label: "Case 2" },
    { x: 50, y: 40, w: 50, h: 30, label: "Case 3" }, { x: 0, y: 70, w: 50, h: 30, label: "Case 4" },
    { x: 50, y: 70, w: 50, h: 30, label: "Case 5" },
  ]},
  { slug: "5-action", vibe: "action", gutter: 3, panels: [
    { x: 0, y: 0, w: 40, h: 50, label: "Case 1" }, { x: 40, y: 0, w: 60, h: 30, label: "Case 2" },
    { x: 40, y: 30, w: 60, h: 20, label: "Case 3" }, { x: 0, y: 50, w: 50, h: 50, label: "Case 4" },
    { x: 50, y: 50, w: 50, h: 50, label: "Case 5" },
  ]},
  { slug: "5-drama", vibe: "drama", gutter: 5, panels: [
    { x: 0, y: 0, w: 50, h: 35, label: "Case 1" }, { x: 50, y: 0, w: 50, h: 35, label: "Case 2" },
    { x: 0, y: 35, w: 100, h: 30, label: "Case 3" }, { x: 0, y: 65, w: 50, h: 35, label: "Case 4" },
    { x: 50, y: 65, w: 50, h: 35, label: "Case 5" },
  ]},
  { slug: "6-grid", vibe: "calm", gutter: 3, panels: [
    { x: 0, y: 0, w: 33, h: 50, label: "Case 1" }, { x: 33, y: 0, w: 34, h: 50, label: "Case 2" },
    { x: 67, y: 0, w: 33, h: 50, label: "Case 3" }, { x: 0, y: 50, w: 33, h: 50, label: "Case 4" },
    { x: 33, y: 50, w: 34, h: 50, label: "Case 5" }, { x: 67, y: 50, w: 33, h: 50, label: "Case 6" },
  ]},
  { slug: "6-action", vibe: "action", gutter: 3, panels: [
    { x: 0, y: 0, w: 50, h: 35, label: "Case 1" }, { x: 50, y: 0, w: 50, h: 35, label: "Case 2" },
    { x: 0, y: 35, w: 33, h: 30, label: "Case 3" }, { x: 33, y: 35, w: 34, h: 30, label: "Case 4" },
    { x: 67, y: 35, w: 33, h: 30, label: "Case 5" }, { x: 0, y: 65, w: 100, h: 35, label: "Case 6" },
  ]},
  { slug: "6-story", vibe: "story", gutter: 4, panels: [
    { x: 0, y: 0, w: 100, h: 30, label: "Case 1" }, { x: 0, y: 30, w: 50, h: 25, label: "Case 2" },
    { x: 50, y: 30, w: 50, h: 25, label: "Case 3" }, { x: 0, y: 55, w: 33, h: 22, label: "Case 4" },
    { x: 33, y: 55, w: 34, h: 22, label: "Case 5" }, { x: 67, y: 55, w: 33, h: 22, label: "Case 6" },
  ]},
  { slug: "7-story", vibe: "story", gutter: 3, panels: [
    { x: 0, y: 0, w: 100, h: 30, label: "Case 1" }, { x: 0, y: 30, w: 33, h: 25, label: "Case 2" },
    { x: 33, y: 30, w: 34, h: 25, label: "Case 3" }, { x: 67, y: 30, w: 33, h: 25, label: "Case 4" },
    { x: 0, y: 55, w: 33, h: 22, label: "Case 5" }, { x: 33, y: 55, w: 34, h: 22, label: "Case 6" },
    { x: 67, y: 55, w: 33, h: 22, label: "Case 7" },
  ]},
  { slug: "7-action", vibe: "action", gutter: 3, panels: [
    { x: 0, y: 0, w: 40, h: 40, label: "Case 1" }, { x: 40, y: 0, w: 60, h: 25, label: "Case 2" },
    { x: 40, y: 25, w: 60, h: 15, label: "Case 3" }, { x: 0, y: 40, w: 50, h: 30, label: "Case 4" },
    { x: 50, y: 40, w: 50, h: 30, label: "Case 5" }, { x: 0, y: 70, w: 50, h: 30, label: "Case 6" },
    { x: 50, y: 70, w: 50, h: 30, label: "Case 7" },
  ]},
  { slug: "8-grid", vibe: "calm", gutter: 3, panels: [
    { x: 0, y: 0, w: 25, h: 50, label: "Case 1" }, { x: 25, y: 0, w: 25, h: 50, label: "Case 2" },
    { x: 50, y: 0, w: 25, h: 50, label: "Case 3" }, { x: 75, y: 0, w: 25, h: 50, label: "Case 4" },
    { x: 0, y: 50, w: 25, h: 50, label: "Case 5" }, { x: 25, y: 50, w: 25, h: 50, label: "Case 6" },
    { x: 50, y: 50, w: 25, h: 50, label: "Case 7" }, { x: 75, y: 50, w: 25, h: 50, label: "Case 8" },
  ]},
  { slug: "8-action", vibe: "action", gutter: 3, panels: [
    { x: 0, y: 0, w: 33, h: 35, label: "Case 1" }, { x: 33, y: 0, w: 34, h: 35, label: "Case 2" },
    { x: 67, y: 0, w: 33, h: 35, label: "Case 3" }, { x: 0, y: 35, w: 33, h: 30, label: "Case 4" },
    { x: 33, y: 35, w: 34, h: 30, label: "Case 5" }, { x: 67, y: 35, w: 33, h: 30, label: "Case 6" },
    { x: 0, y: 65, w: 50, h: 35, label: "Case 7" }, { x: 50, y: 65, w: 50, h: 35, label: "Case 8" },
  ]},
];
