// Bibliothèque de poses OpenPose + rendu squelette + foreshortening.
// Module pur (aucun effet de bord) → testable isolément.

import { Poseless, ForeshortenRule } from "../types.ts";
import { pngEncode } from "./image.ts";

export const POSE_W = 256, POSE_H = 384;

export const POSES: Record<string, Poseless> = {
  // --- original 12 poses ---
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
  // --- 12 new dynamic action poses ---
  "action-high-punch": [
    [128,48],[128,76],[96,76],[72,104],[60,130],[160,76],[180,34],[208,22],
    [104,150],[108,210],[104,300],[152,150],[148,210],[150,300],
    [118,42],[138,42],[110,46],[146,46],
  ],
  "action-spin-kick": [
    [128,50],[128,78],[88,78],[56,62],[40,42],[168,78],[196,58],[220,38],
    [104,150],[108,210],[104,300],[152,150],[176,200],[200,240],
    [118,44],[138,44],[110,48],[146,48],
  ],
  "action-leap": [
    [128,32],[128,60],[96,60],[72,36],[56,20],[160,60],[188,84],[208,110],
    [100,140],[80,190],[64,230],[156,140],[176,190],[196,230],
    [118,26],[138,26],[110,30],[146,30],
  ],
  "action-dodge": [
    [128,56],[128,82],[92,84],[68,112],[52,140],[164,84],[192,110],[216,134],
    [100,156],[96,216],[92,310],[156,156],[160,216],[164,310],
    [118,50],[138,50],[110,54],[146,54],
  ],
  "action-ground-punch": [
    [128,120],[128,145],[100,150],[56,160],[40,140],[156,150],[200,140],[212,120],
    [96,220],[100,280],[96,340],[160,220],[156,280],[160,340],
    [118,114],[138,114],[110,118],[146,118],
  ],
  "action-air-kick": [
    [128,28],[128,56],[92,56],[68,36],[52,20],[164,56],[184,80],[200,108],
    [100,136],[80,184],[56,224],[156,136],[176,184],[200,220],
    [118,22],[138,22],[110,26],[146,26],
  ],
  "action-grab-thrust": [
    [128,50],[128,78],[92,80],[72,106],[56,130],[168,78],[196,52],[224,30],
    [104,150],[104,210],[100,306],[152,150],[152,210],[156,306],
    [118,44],[138,44],[110,48],[146,48],
  ],
  "action-power-up": [
    [128,44],[128,72],[96,72],[80,104],[68,136],[160,72],[176,104],[188,136],
    [100,150],[100,210],[96,300],[156,150],[156,210],[160,300],
    [118,38],[138,38],[110,42],[146,42],
  ],
  "action-slash": [
    [128,46],[128,74],[88,74],[56,52],[36,32],[168,74],[196,48],[224,26],
    [100,148],[96,206],[92,300],[156,148],[160,206],[164,300],
    [118,40],[138,40],[110,44],[146,44],
  ],
  "emotion-triumph": [
    [128,52],[128,80],[92,80],[60,56],[44,36],[164,80],[196,56],[212,36],
    [104,150],[104,210],[100,306],[152,150],[152,210],[156,306],
    [118,46],[138,46],[110,50],[146,50],
  ],
  "emotion-taunt": [
    [128,56],[128,84],[96,84],[76,110],[64,136],[160,84],[184,112],[228,140],
    [104,156],[108,216],[104,306],[152,156],[148,216],[150,306],
    [118,50],[138,50],[110,54],[146,54],
  ],
  "emotion-despair": [
    [128,60],[128,88],[96,88],[80,116],[72,148],[160,88],[176,116],[184,148],
    [104,164],[112,224],[116,310],[152,164],[148,224],[144,310],
    [118,54],[138,54],[110,58],[146,58],
  ],
  // --- 5 two-character interaction poses (36 keypoints = 18 per char) ---
  "interact-punch-block": [
    [96,48],[96,76],[76,76],[52,56],[36,36],[116,76],[144,56],[168,34],
    [84,150],[80,210],[76,304],[108,150],[112,210],[116,304],
    [88,42],[104,42],[80,46],[112,46],
    [176,50],[176,78],[160,80],[180,52],[200,32],[192,80],[176,56],[160,38],
    [164,148],[164,208],[168,302],[188,148],[188,208],[184,302],
    [168,44],[184,44],[160,48],[192,48],
  ],
  "interact-clash": [
    [96,48],[96,76],[76,76],[52,56],[36,36],[116,76],[144,56],[168,34],
    [84,150],[80,210],[76,304],[108,150],[112,210],[116,304],
    [88,42],[104,42],[80,46],[112,46],
    [160,48],[160,76],[180,76],[204,56],[220,36],[140,76],[112,56],[88,34],
    [172,150],[176,210],[180,304],[148,150],[144,210],[140,304],
    [152,42],[168,42],[176,46],[160,46],
  ],
  "interact-grab": [
    [96,48],[96,76],[76,76],[52,56],[36,36],[116,76],[144,56],[168,34],
    [84,150],[80,210],[76,304],[108,150],[112,210],[116,304],
    [88,42],[104,42],[80,46],[112,46],
    [168,52],[168,80],[152,80],[176,106],[194,132],[184,80],[176,108],[168,134],
    [164,152],[164,212],[168,306],[172,152],[172,212],[176,306],
    [160,46],[176,46],[152,50],[184,50],
  ],
  "interact-throw": [
    [96,48],[96,76],[76,76],[48,100],[28,130],[116,76],[144,96],[164,124],
    [84,150],[80,210],[76,304],[108,150],[112,210],[116,304],
    [88,42],[104,42],[80,46],[112,46],
    [184,40],[184,68],[168,68],[172,98],[168,128],[200,68],[196,98],[192,128],
    [172,150],[164,210],[156,300],[196,150],[204,210],[212,300],
    [176,34],[192,34],[168,38],[200,38],
  ],
  "interact-air-kick": [
    [80,28],[80,56],[64,56],[40,40],[24,24],[96,56],[120,80],[140,108],
    [72,136],[60,184],[48,270],[88,136],[100,184],[112,270],
    [72,22],[88,22],[64,26],[96,26],
    [190,50],[190,78],[174,78],[178,104],[172,130],[206,78],[200,104],[194,130],
    [176,156],[164,216],[156,310],[204,156],[216,216],[224,310],
    [182,44],[198,44],[174,48],[206,48],
  ],
};

export const SKELETON_CONNECTIONS: [number, number][] = [
  [0,1],[1,2],[2,3],[3,4],[1,5],[5,6],[6,7],
  [1,8],[8,9],[9,10],[1,11],[11,12],[12,13],
  [0,14],[14,16],[0,15],[15,17],[0,1],
];

// ---------- Foreshortening segmentaire (2D qui simule la 3D) ----------
const LIMB_SEGMENTS: Record<string, { root: number; joints: number[] }> = {
  "left-arm":  { root: 2,  joints: [3, 4] },
  "right-arm": { root: 5,  joints: [6, 7] },
  "left-leg":  { root: 8,  joints: [9, 10] },
  "right-leg": { root: 11, joints: [12, 13] },
  "head":      { root: 1,  joints: [0, 14, 15, 16, 17] },
};

const FORESHORTEN_MAP: Record<string, ForeshortenRule[]> = {
  "action-punch":       [{ limb: "right-arm", scales: [1.3, 2.2] }],
  "action-high-punch":  [{ limb: "right-arm", scales: [1.4, 2.5] }],
  "action-kick":        [{ limb: "right-leg", scales: [1.3, 2.2] }],
  "action-spin-kick":   [{ limb: "right-leg", scales: [1.4, 2.5] }],
  "action-air-kick":    [{ limb: "right-leg", scales: [1.3, 2.0] }],
  "action-slash":       [{ limb: "right-arm", scales: [1.2, 2.5] }],
  "action-grab-thrust": [{ limb: "right-arm", scales: [1.2, 1.8] }],
  "action-leap":        [{ limb: "left-leg", scales: [1.2, 1.5] }, { limb: "right-leg", scales: [1.2, 1.5] }],
  "action-jump":        [{ limb: "left-leg", scales: [1.1, 1.3] }, { limb: "right-leg", scales: [1.1, 1.3] }],
  "action-ground-punch":[{ limb: "left-arm", scales: [1.2, 1.8] }],
  "action-swing":       [{ limb: "right-arm", scales: [1.1, 1.8] }],
  "action-defend":      [{ limb: "left-arm", scales: [1.1, 1.2] }, { limb: "right-arm", scales: [1.1, 1.2] }],
  "action-duel":        [{ limb: "right-arm", scales: [1.1, 1.4] }],
  "action-point":       [{ limb: "right-arm", scales: [1.1, 1.5] }],
  "action-power-up":    [{ limb: "left-arm", scales: [1.1, 1.3] }, { limb: "right-arm", scales: [1.1, 1.3] }],
  "emotion-triumph":    [{ limb: "right-arm", scales: [1.1, 1.5] }],
  "emotion-taunt":      [{ limb: "right-arm", scales: [1.2, 1.8] }],
  "interact-punch-block": [
    { limb: "right-arm", scales: [1.3, 2.2], char: 0 },
    { limb: "left-arm",  scales: [1.2, 1.8], char: 1 },
  ],
  "interact-clash": [
    { limb: "right-arm", scales: [1.3, 2.0], char: 0 },
    { limb: "left-arm",  scales: [1.3, 2.0], char: 1 },
  ],
  "interact-grab": [
    { limb: "right-arm", scales: [1.2, 1.8], char: 0 },
    { limb: "left-arm",  scales: [1.1, 1.3], char: 1 },
  ],
  "interact-throw": [
    { limb: "right-arm", scales: [1.2, 1.8], char: 0 },
    { limb: "left-arm",  scales: [1.2, 1.5], char: 1 },
  ],
  "interact-air-kick": [
    { limb: "right-leg", scales: [1.3, 2.0], char: 0 },
    { limb: "left-arm",  scales: [1.2, 1.5], char: 1 },
  ],
};

export function applyForeshortening(kps: Poseless, poseKey: string, angle: string): Poseless {
  const out = kps.map((kp) => [kp[0], kp[1]]) as [number, number][];
  const isInteraction = kps.length > 18;

  for (const [prefix, rules] of Object.entries(FORESHORTEN_MAP)) {
    if (!poseKey.startsWith(prefix)) continue;
    for (const { limb, scales, char } of rules) {
      const seg = LIMB_SEGMENTS[limb];
      if (!seg) continue;
      const offset = (isInteraction && char === 1) ? 18 : 0;
      const root = out[seg.root + offset];
      for (let si = 0; si < seg.joints.length && si < scales.length; si++) {
        const ji = seg.joints[si] + offset;
        const dx = out[ji][0] - root[0];
        const dy = out[ji][1] - root[1];
        out[ji][0] = Math.round(root[0] + dx * scales[si]);
        out[ji][1] = Math.round(root[1] + dy * scales[si]);
      }
    }
    break;
  }

  // Clamp to canvas
  const clamped = out.map(([x, y]) => [
    Math.max(0, Math.min(POSE_W - 1, x)),
    Math.max(0, Math.min(POSE_H - 1, y)),
  ]) as Poseless;

  // Apply camera angle adjustment
  const cx = POSE_W / 2, cy = POSE_H / 2;
  let sx = 1, sy = 1, dx = 0, dy = 0;
  switch (angle) {
    case "low-angle":  sx = 0.85; sy = 0.85; dy = -30; break;
    case "high-angle": sx = 0.9;  sy = 0.75; dy = 20;  break;
    case "bird":       sx = 0.7;  sy = 0.6;  dy = -40; break;
    case "worm":       sx = 1.15; sy = 0.8;  dy = -50; break;
  }
  return clamped.map(([x, y]) => {
    const nx = Math.round(cx + (x - cx) * sx + dx);
    const ny = Math.round(cy + (y - cy) * sy + dy);
    return [Math.max(0, Math.min(POSE_W - 1, nx)), Math.max(0, Math.min(POSE_H - 1, ny))];
  }) as Poseless;
}

export function mirrorPose(kps: Poseless): Poseless {
  return kps.map(([x, y]) => [POSE_W - 1 - x, y]) as Poseless;
}

export function renderSkeleton(kps: Poseless): Uint8Array {
  const stride = 4;
  const pixels = new Uint8Array(POSE_H * POSE_W * stride);
  const isInteraction = kps.length > 18;

  function setPx(x: number, y: number, r: number, g: number, b: number) {
    if (x < 0 || x >= POSE_W || y < 0 || y >= POSE_H) return;
    const i = (y * POSE_W + x) * stride;
    pixels[i]=r; pixels[i+1]=g; pixels[i+2]=b; pixels[i+3]=255;
  }

  function line(x1: number, y1: number, x2: number, y2: number, r: number, g: number, b: number) {
    const dx = Math.abs(x2 - x1), dy = Math.abs(y2 - y1);
    const sx = x1 < x2 ? 1 : -1, sy = y1 < y2 ? 1 : -1;
    let err = dx - dy, x = x1, y = y1;
    while (true) {
      setPx(x, y, r, g, b);
      if (x === x2 && y === y2) break;
      const e2 = err * 2;
      if (e2 > -dy) { err -= dy; x += sx; }
      if (e2 < dx) { err += dx; y += sy; }
    }
  }

  function weightedLine(x1: number, y1: number, x2: number, y2: number, r: number, g: number, b: number, weight: number) {
    if (weight <= 1) { line(x1, y1, x2, y2, r, g, b); return; }
    const dx = x2 - x1, dy = y2 - y1;
    const len = Math.sqrt(dx*dx + dy*dy) || 1;
    const px = -dy / len, py = dx / len;
    const half = Math.floor(weight / 2);
    for (let w = -half; w <= half; w++) {
      const ox = Math.round(px * w), oy = Math.round(py * w);
      line(x1 + ox, y1 + oy, x2 + ox, y2 + oy, r, g, b);
    }
  }

  function circle(cx: number, cy: number, r: number, cr: number, cg: number, cb: number) {
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        if (dx * dx + dy * dy <= r * r) setPx(cx + dx, cy + dy, cr, cg, cb);
      }
    }
  }

  function drawSingleChar(start: number, colR: number, colG: number, colB: number) {
    // Compute segment lengths for variable line weight (longer = closer = thicker)
    const lengths = SKELETON_CONNECTIONS.map(([i, j]) => {
      const dx = kps[start+j][0] - kps[start+i][0], dy = kps[start+j][1] - kps[start+i][1];
      return Math.sqrt(dx*dx + dy*dy);
    });
    const minLen = Math.min(...lengths, 1);
    const maxLen = Math.max(...lengths, minLen + 1);

    // Draw connections with variable weight (1–3)
    for (let ci = 0; ci < SKELETON_CONNECTIONS.length; ci++) {
      const [i, j] = SKELETON_CONNECTIONS[ci];
      const weight = 1 + 2 * (lengths[ci] - minLen) / (maxLen - minLen);
      weightedLine(kps[start+i][0], kps[start+i][1], kps[start+j][0], kps[start+j][1],
        colR, colG, colB, Math.round(weight));
    }

    // Torso center for depth heuristic
    const torsoX = (kps[start+2][0] + kps[start+5][0] + kps[start+8][0] + kps[start+11][0]) / 4;
    const torsoY = (kps[start+2][1] + kps[start+5][1] + kps[start+8][1] + kps[start+11][1]) / 4;

    // Draw joints with variable size (farther from torso = closer to camera = larger)
    for (let i = start; i < start + 18; i++) {
      const dist = Math.sqrt((kps[i][0] - torsoX) ** 2 + (kps[i][1] - torsoY) ** 2);
      const jointR = Math.max(2, Math.min(7, Math.round(2 + dist / 40)));
      circle(kps[i][0], kps[i][1], jointR, colR, colG, colB);
    }

    // Draw head
    circle(kps[start+0][0], kps[start+0][1], 12, colR, colG, colB);
  }

  // Draw character A in white
  drawSingleChar(0, 255, 255, 255);

  // Draw character B in light blue if interaction
  if (isInteraction) {
    drawSingleChar(18, 100, 180, 255);
  }

  return pngEncode(POSE_W, POSE_H, pixels);
}
