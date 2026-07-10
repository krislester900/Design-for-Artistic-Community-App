import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") ?? "";
const REPLICATE_API_KEY = Deno.env.get("REPLICATE_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const SDXL = { owner: "rocketdigitalai", name: "animagine-xl-4.0", version: "7af46ee494f1cf196d49a8592737f4eb789e34a5a995751b23a869d19f5dc2ba" };
const DENOISE_STRENGTH = 0.55;

interface PanelLayout { x: number; y: number; w: number; h: number; label: string; breakFrame?: boolean; }

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

type Poseless = [number, number][]; // 18 keypoints per character [x,y] in POSE_W×POSE_H space

const POSES: Record<string, Poseless> = {
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

// ---------- Foreshortening segmentaire (2D qui simule la 3D) ----------
const LIMB_SEGMENTS: Record<string, { root: number; joints: number[] }> = {
  "left-arm":  { root: 2,  joints: [3, 4] },
  "right-arm": { root: 5,  joints: [6, 7] },
  "left-leg":  { root: 8,  joints: [9, 10] },
  "right-leg": { root: 11, joints: [12, 13] },
  "head":      { root: 1,  joints: [0, 14, 15, 16, 17] },
};

type ForeshortenRule = { limb: string; scales: number[]; char?: number };

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

function applyForeshortening(kps: Poseless, poseKey: string, angle: string): Poseless {
  const out = kps.map(kp => [kp[0], kp[1]]) as [number, number][];
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

function mirrorPose(kps: Poseless): Poseless {
  return kps.map(([x, y]) => [POSE_W - 1 - x, y]) as Poseless;
}

function renderSkeleton(kps: Poseless): Uint8Array {
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

    const poseKeys = Object.keys(POSES).filter(k => !k.startsWith("interact-")).join(", ");
    const interactKeys = Object.keys(POSES).filter(k => k.startsWith("interact-")).join(", ");

    const systemPrompt = `Tu es un **scénariste et storyboarder manga** expert (style gekiga/shonen/seinen).
Tu découpes une scène en EXACTEMENT ${panelCount} cases pour une planche de manga.

RÈGLES NARRATIVES MANGA :
- Case 1 : plan d'ensemble ou d'ambiance (établir le lieu, la météo, l'émotion)
- Cases 2 à ${panelCount - 1} : montée dramatique, alterner plans larges et gros plans
- Dernière case : climax ou cliffhanger (gros plan ou plan large poignant)
- Utiliser le rythme : 1 case = 1 action principale
- **Actions dynamiques** : varie les poses (saut, esquive, coup de poing, coup de pied, garde, etc.)
- **Perspective** : utilise low-angle et worm pour des plans dramatiques et puissants; high-angle/bird pour la vulnérabilité
- **Interactions** : si 2 personnages s'affrontent, utilise une pose d'interaction : ${interactKeys}

Pour CHAQUE case, fournis ces champs :
- scene : description visuelle du décor + action + émotion (riche, sensorielle)
- characters : nom du/des personnages présents + leur état émotionnel
- dialogue : réplique en français (vide si case muette)
- narration : texte de narration/hors-champ (vide si pas de narration)
- framing : wide | medium | close-up | extreme-close-up
- camera_angle : eye-level | high-angle | low-angle | bird | worm
- emotion : l'émotion dominante de la case
- action : l'action principale en 1 phrase courte, avec verbe d'action fort
- pose_description : choisir PARMI cette liste (la plus proche de l'action) : ${poseKeys}. Pour les combats à 2, utilise une pose d'interaction : ${interactKeys}

Retourne UNIQUEMENT un JSON array valide. Exemple :
[
  {"panel_index":0,"scene":"...","characters":"...","dialogue":"","narration":"","framing":"wide","camera_angle":"high-angle","emotion":"mélancolie","action":"...","pose_description":"neutral-stand"},
  ...
]`;

    const userPrompt = `SCÈNE À DÉCOUPER : ${scene}

${charSection}

NOMBRE DE CASES : ${panelCount}

Génère un découpage narratif professionnel avec progression dramatique et des poses d'action variées.
Chaque case doit avoir un pose_description valide. Pour les affrontements, utilise les poses interact-*.
Angles de caméra dynamiques recommandés : low-angle, worm pour l'action; high-angle, bird pour la vulnérabilité.`;

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
  supabase: any, plancheId: string, panels: any[], layoutPanels: PanelLayout[], style: any, gutter: number = 3, pageNumber: number = 1
): Promise<string | null> {
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

      // Step 6: Upscale the composite image
      const upscaledUrl = await upscaleImage(publicUrl);
      if (upscaledUrl) {
        const upscaledFileName = `composites/${plancheId}_upscaled.png`;
        try {
          const upscaledBuf = await (await fetch(upscaledUrl)).arrayBuffer();
          await supabase.storage.from("planche-assets").upload(upscaledFileName, new Uint8Array(upscaledBuf), { contentType: "image/png", upsert: true });
          const { data: { publicUrl: upscaledPublicUrl } } = supabase.storage.from("planche-assets").getPublicUrl(upscaledFileName);
          return upscaledPublicUrl;
        } catch {
          return publicUrl;
        }
      }
      return publicUrl;
    }
  } catch {}
  return null;
}

// ---------- Double-page spread ----------
const SPREAD_W = 4800;
const SPREAD_H = 3400;

async function compositeDoublePageSpread(supabase: any, plancheIds: string[],
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

const UPSCALER = { owner: "nightmareai", name: "real-esrgan", version: "42fed1c4974146d4d2414e2be2c5277c7fcf05fcc3a73abf41610695738c1d7b" };

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

// ============================================================
// BITMAP FONT (8x8) — Public Domain X11 font, ASCII 32-126
// ============================================================
const FONT8X8 = new Uint8Array([
  // 32 space
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  // 33 !
  0x18,0x3C,0x3C,0x18,0x18,0x00,0x18,0x00,
  // 34 "
  0x66,0x66,0x66,0x24,0x00,0x00,0x00,0x00,
  // 35 #
  0x36,0x36,0x7F,0x36,0x36,0x7F,0x36,0x36,
  // 36 $
  0x18,0x3E,0x60,0x3E,0x06,0x7C,0x18,0x00,
  // 37 %
  0x63,0x66,0x0C,0x18,0x30,0x66,0x46,0x00,
  // 38 &
  0x1C,0x36,0x36,0x1C,0x3B,0x6E,0x3B,0x00,
  // 39 '
  0x18,0x18,0x30,0x00,0x00,0x00,0x00,0x00,
  // 40 (
  0x0C,0x18,0x30,0x30,0x30,0x18,0x0C,0x00,
  // 41 )
  0x30,0x18,0x0C,0x0C,0x0C,0x18,0x30,0x00,
  // 42 *
  0x24,0x66,0x3C,0xFF,0x3C,0x66,0x24,0x00,
  // 43 +
  0x18,0x18,0x18,0x7E,0x18,0x18,0x18,0x00,
  // 44 ,
  0x00,0x00,0x00,0x00,0x18,0x18,0x30,0x00,
  // 45 -
  0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00,
  // 46 .
  0x00,0x00,0x00,0x00,0x00,0x00,0x18,0x00,
  // 47 /
  0x02,0x06,0x0C,0x18,0x30,0x60,0x40,0x00,
  // 48 0
  0x3C,0x66,0x6E,0x76,0x66,0x66,0x3C,0x00,
  // 49 1
  0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00,
  // 50 2
  0x3C,0x66,0x06,0x0C,0x18,0x30,0x7E,0x00,
  // 51 3
  0x3C,0x66,0x06,0x1C,0x06,0x66,0x3C,0x00,
  // 52 4
  0x0C,0x1C,0x3C,0x6C,0x7E,0x0C,0x0C,0x00,
  // 53 5
  0x7E,0x60,0x60,0x7C,0x06,0x46,0x3C,0x00,
  // 54 6
  0x3C,0x66,0x60,0x7C,0x66,0x66,0x3C,0x00,
  // 55 7
  0x7E,0x06,0x0C,0x18,0x30,0x30,0x30,0x00,
  // 56 8
  0x3C,0x66,0x66,0x3C,0x66,0x66,0x3C,0x00,
  // 57 9
  0x3C,0x66,0x66,0x3E,0x06,0x66,0x3C,0x00,
  // 58 :
  0x00,0x18,0x00,0x00,0x00,0x18,0x00,0x00,
  // 59 ;
  0x00,0x18,0x00,0x00,0x18,0x18,0x30,0x00,
  // 60 <
  0x06,0x0C,0x18,0x30,0x18,0x0C,0x06,0x00,
  // 61 =
  0x00,0x00,0x7E,0x00,0x7E,0x00,0x00,0x00,
  // 62 >
  0x30,0x18,0x0C,0x06,0x0C,0x18,0x30,0x00,
  // 63 ?
  0x3C,0x66,0x06,0x0C,0x18,0x00,0x18,0x00,
  // 64 @
  0x3C,0x66,0x6E,0x6E,0x60,0x62,0x3C,0x00,
  // 65 A
  0x18,0x3C,0x66,0x66,0x7E,0x66,0x66,0x00,
  // 66 B
  0x7C,0x66,0x66,0x7C,0x66,0x66,0x7C,0x00,
  // 67 C
  0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00,
  // 68 D
  0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00,
  // 69 E
  0x7E,0x60,0x60,0x7C,0x60,0x60,0x7E,0x00,
  // 70 F
  0x7E,0x60,0x60,0x7C,0x60,0x60,0x60,0x00,
  // 71 G
  0x3C,0x66,0x60,0x60,0x6E,0x66,0x3C,0x00,
  // 72 H
  0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00,
  // 73 I
  0x7E,0x18,0x18,0x18,0x18,0x18,0x7E,0x00,
  // 74 J
  0x1E,0x06,0x06,0x06,0x46,0x66,0x3C,0x00,
  // 75 K
  0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00,
  // 76 L
  0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00,
  // 77 M
  0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00,
  // 78 N
  0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00,
  // 79 O
  0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00,
  // 80 P
  0x7C,0x66,0x66,0x66,0x7C,0x60,0x60,0x00,
  // 81 Q
  0x3C,0x66,0x66,0x66,0x6E,0x3C,0x07,0x00,
  // 82 R
  0x7C,0x66,0x66,0x7C,0x78,0x6C,0x66,0x00,
  // 83 S
  0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00,
  // 84 T
  0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00,
  // 85 U
  0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00,
  // 86 V
  0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0x00,
  // 87 W
  0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00,
  // 88 X
  0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00,
  // 89 Y
  0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00,
  // 90 Z
  0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0x00,
  // 91 [
  0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00,
  // 92 backslash
  0x40,0x60,0x30,0x18,0x0C,0x06,0x02,0x00,
  // 93 ]
  0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00,
  // 94 ^
  0x18,0x3C,0x66,0x00,0x00,0x00,0x00,0x00,
  // 95 _
  0x00,0x00,0x00,0x00,0x00,0x00,0x7E,0x00,
  // 96 `
  0x18,0x18,0x0C,0x00,0x00,0x00,0x00,0x00,
  // 97 a
  0x00,0x00,0x3C,0x06,0x3E,0x66,0x3E,0x00,
  // 98 b
  0x60,0x60,0x7C,0x66,0x66,0x66,0x7C,0x00,
  // 99 c
  0x00,0x00,0x3C,0x66,0x60,0x66,0x3C,0x00,
  // 100 d
  0x06,0x06,0x3E,0x66,0x66,0x66,0x3E,0x00,
  // 101 e
  0x00,0x00,0x3C,0x66,0x7E,0x60,0x3C,0x00,
  // 102 f
  0x1C,0x36,0x30,0x7C,0x30,0x30,0x30,0x00,
  // 103 g
  0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x3C,
  // 104 h
  0x60,0x60,0x7C,0x66,0x66,0x66,0x66,0x00,
  // 105 i
  0x18,0x00,0x38,0x18,0x18,0x18,0x3C,0x00,
  // 106 j
  0x06,0x00,0x06,0x06,0x06,0x66,0x66,0x3C,
  // 107 k
  0x60,0x60,0x66,0x6C,0x78,0x6C,0x66,0x00,
  // 108 l
  0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00,
  // 109 m
  0x00,0x00,0x7C,0x7E,0x6A,0x6A,0x6A,0x00,
  // 110 n
  0x00,0x00,0x7C,0x66,0x66,0x66,0x66,0x00,
  // 111 o
  0x00,0x00,0x3C,0x66,0x66,0x66,0x3C,0x00,
  // 112 p
  0x00,0x00,0x7C,0x66,0x66,0x7C,0x60,0x60,
  // 113 q
  0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x06,
  // 114 r
  0x00,0x00,0x7C,0x66,0x60,0x60,0x60,0x00,
  // 115 s
  0x00,0x00,0x3E,0x60,0x3C,0x06,0x7C,0x00,
  // 116 t
  0x30,0x30,0x7E,0x30,0x30,0x36,0x1C,0x00,
  // 117 u
  0x00,0x00,0x66,0x66,0x66,0x66,0x3E,0x00,
  // 118 v
  0x00,0x00,0x66,0x66,0x66,0x3C,0x18,0x00,
  // 119 w
  0x00,0x00,0x6A,0x6A,0x6A,0x7E,0x3C,0x00,
  // 120 x
  0x00,0x00,0x66,0x3C,0x18,0x3C,0x66,0x00,
  // 121 y
  0x00,0x00,0x66,0x66,0x66,0x3E,0x06,0x3C,
  // 122 z
  0x00,0x00,0x7E,0x0C,0x18,0x30,0x7E,0x00,
  // 123 {
  0x0E,0x18,0x18,0x70,0x18,0x18,0x0E,0x00,
  // 124 |
  0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x00,
  // 125 }
  0x70,0x18,0x18,0x0E,0x18,0x18,0x70,0x00,
  // 126 ~
  0x3B,0x6E,0x00,0x00,0x00,0x00,0x00,0x00,
]);

const FONT_W = 8;
const FONT_H = 8;

function renderTextOnPage(page: Uint8Array, pw: number, ph: number, text: string, px: number, py: number, scale: number, fg: number, bg: number) {
  const upper = text.toUpperCase();
  for (let ci = 0; ci < upper.length; ci++) {
    const code = upper.charCodeAt(ci);
    if (code < 32 || code > 126) continue;
    const off = (code - 32) * FONT_H;
    for (let r = 0; r < FONT_H; r++) {
      const row = off + r;
      const bits = row < FONT8X8.length ? FONT8X8[row] : 0;
      for (let c = 0; c < FONT_W; c++) {
        if (!(bits & (0x80 >> c))) continue;
        for (let sy = 0; sy < scale; sy++) {
          for (let sx = 0; sx < scale; sx++) {
            const x = px + ci * FONT_W * scale + c * scale + sx;
            const y = py + r * scale + sy;
            if (x < 0 || x >= pw || y < 0 || y >= ph) continue;
            const i = (y * pw + x) * 4;
            page[i] = fg;
            page[i+1] = fg;
            page[i+2] = fg;
            page[i+3] = 255;
          }
        }
      }
    }
  }
}

function textWidth(text: string, scale: number): number {
  return text.length * FONT_W * scale;
}

function textHeight(scale: number): number {
  return FONT_H * scale;
}

function drawEllipse(page: Uint8Array, pw: number, ph: number, cx: number, cy: number, rx: number, ry: number, fill: number, stroke: number) {
  for (let y = cy - ry; y <= cy + ry; y++) {
    for (let x = cx - rx; x <= cx + rx; x++) {
      const dx = x - cx, dy = y - cy;
      const inside = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1;
      if (!inside) continue;
      const edge = Math.abs((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) - 1);
      let col: number, a: number;
      if (edge < 0.05 && stroke >= 0) {
        col = stroke; a = 255;
      } else {
        col = fill; a = fill === 255 ? 255 : (fill >= 0 ? 255 : 0);
      }
      if (x < 0 || x >= pw || y < 0 || y >= ph) continue;
      const i = (y * pw + x) * 4;
      page[i] = col; page[i+1] = col; page[i+2] = col; page[i+3] = a;
    }
  }
}

function drawLine(page: Uint8Array, pw: number, ph: number, x1: number, y1: number, x2: number, y2: number, color: number) {
  const dx = Math.abs(x2 - x1), dy = Math.abs(y2 - y1);
  const sx = x1 < x2 ? 1 : -1, sy = y1 < y2 ? 1 : -1;
  let err = dx - dy, x = x1, y = y1;
  while (true) {
    if (x >= 0 && x < pw && y >= 0 && y < ph) {
      const i = (y * pw + x) * 4;
      page[i] = color; page[i+1] = color; page[i+2] = color; page[i+3] = 255;
    }
    if (x === x2 && y === y2) break;
    const e2 = err * 2;
    if (e2 > -dy) { err -= dy; x += sx; }
    if (e2 < dx) { err += dx; y += sy; }
  }
}

function drawMangaSpeechBubble(page: Uint8Array, pw: number, ph: number,
  bubbleX: number, bubbleY: number, bubbleW: number, bubbleH: number,
  text: string, tailDir: string,
  scale: number) {
  const cx = bubbleX + bubbleW / 2;
  const cy = bubbleY + bubbleH / 2;
  const rx = bubbleW / 2;
  const ry = bubbleH / 2;

  // Fill bubble white with black outline
  drawEllipse(page, pw, ph, cx, cy, rx, ry, 255, 0);

  // Draw tail pointer (triangle from bubble edge toward speaker)
  let tx: number, ty: number, dirX: number, dirY: number;
  const tailLen = 24;
  switch (tailDir) {
    case "bottom-left": tx = cx - rx * 0.4; ty = cy + ry; dirX = -1; dirY = 1; break;
    case "bottom-right": tx = cx + rx * 0.4; ty = cy + ry; dirX = 1; dirY = 1; break;
    default: tx = cx; ty = cy + ry; dirX = 0; dirY = 1; break;
  }
  // Draw tail as two lines from edge outward
  const tailEndX = tx + dirX * tailLen;
  const tailEndY = ty + dirY * tailLen;
  for (let i = 0; i <= 6; i++) {
    const t = i / 6;
    const lx = tx + (tailEndX - tx) * t;
    const ly = ty + (tailEndY - ty) * t;
    const spread = 6 * (1 - t);
    drawLine(page, pw, ph, lx - spread, ly, lx + spread, ly, 0);
  }
  drawLine(page, pw, ph, tx, ty, tailEndX, tailEndY, 0);
  // Fill tail area white
  const tailBaseX = tx, tailBaseY = ty;
  const tailTipX = tailEndX, tailTipY = tailEndY;
  const spreadBase = 8;
  for (let t = 1; t < 1.0; t += 0.1) {
    const mx = tailBaseX + (tailTipX - tailBaseX) * t;
    const my = tailBaseY + (tailTipY - tailBaseY) * t;
    const sp = Math.round(spreadBase * (1 - t));
    for (let s = -sp; s <= sp; s++) {
      const x = Math.round(mx + s);
      const y = Math.round(my);
      if (x >= 0 && x < pw && y >= 0 && y < ph) {
        const i = (y * pw + x) * 4;
        if (page[i] === 0 && page[i+1] === 0 && page[i+2] === 0) continue;
        page[i] = 255; page[i+1] = 255; page[i+2] = 255; page[i+3] = 255;
      }
    }
  }

  // Render text centered in bubble (skip if empty — caller handles multi-line)
  if (text.length > 0) {
    const tw = textWidth(text, scale);
    const th = textHeight(scale);
    const textX = Math.round(cx - tw / 2);
    const textY = Math.round(cy - th / 2);
    renderTextOnPage(page, pw, ph, text, textX, textY, scale, 0, 255);
  }
}

// ============================================================
// POST-PROCESSING: Lineart cleanup (adaptive threshold)
// ============================================================
function applyLineartCleanup(rgba: Uint8Array, w: number, h: number): Uint8Array {
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
function applyScreentone(rgba: Uint8Array, w: number, h: number, density: number = 0.15): Uint8Array {
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
function getScreentoneForEmotion(emotion: string): { type: string; density: number; angle: number } {
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

function applyScreentoneRegion(rgba: Uint8Array, w: number, h: number,
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
const SFX_MAP: Record<string, string> = {
  "punch": "BAM!", "high-punch": "SMASH!", "kick": "WHAM!",
  "spin-kick": "CRACK!", "air-kick": "BAM!", "slash": "SWISH!",
  "clash": "CLANG!", "grab-thrust": "THUD!", "leap": "SOAR!",
  "ground-punch": "CRASH!", "dodge": "SWISH!", "throw": "FLING!",
  "power-up": "SURGE!", "punch-block": "SMASH!", "impact": "BOOM!",
};

function renderSFX(page: Uint8Array, pw: number, ph: number, word: string,
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
function renderPanelNumber(page: Uint8Array, pw: number, ph: number,
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
function applyMotionBlur(rgba: Uint8Array, w: number, h: number,
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

function applyZoomBlur(rgba: Uint8Array, w: number, h: number,
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

function applySmearEffects(rgba: Uint8Array, w: number, h: number,
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
interface AdjacentPair {
  a: number; b: number; dir: "h" | "v";
  gutterX: number; gutterY: number; gutterW: number; gutterH: number;
}

function detectAdjacentPanels(panels: PanelLayout[], gutter: number): AdjacentPair[] {
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

function applyGutterTransition(page: Uint8Array, w: number, h: number,
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

function drawThickLine(rgba: Uint8Array, w: number, h: number,
  x1: number, y1: number, x2: number, y2: number,
  r: number, g: number, b: number, alpha: number, thickness: number = 1): void {
  const dx = x2 - x1, dy = y2 - y1;
  const len = Math.sqrt(dx*dx + dy*dy) || 1;
  const px = -dy / len, py = dx / len;
  const half = Math.floor(thickness / 2);
  for (let t = -half; t <= half; t++) {
    const ox = Math.round(px * t), oy = Math.round(py * t);
    let cx = x1 + ox, cy = y1 + oy;
    const ex = x2 + ox, ey = y2 + oy;
    const ddx = Math.abs(ex - cx), ddy = Math.abs(ey - cy);
    const sx = cx < ex ? 1 : -1, sy = cy < ey ? 1 : -1;
    let err = ddx - ddy;
    while (true) {
      if (cx >= 0 && cx < w && cy >= 0 && cy < h) {
        const i = (cy * w + cx) * 4;
        const blend = alpha / 255;
        rgba[i] = Math.round(rgba[i] * (1 - blend) + r * blend);
        rgba[i+1] = Math.round(rgba[i+1] * (1 - blend) + g * blend);
        rgba[i+2] = Math.round(rgba[i+2] * (1 - blend) + b * blend);
      }
      if (cx === ex && cy === ey) break;
      const e2 = err * 2;
      if (e2 > -ddy) { err -= ddy; cx += sx; }
      if (e2 < ddx) { err += ddx; cy += sy; }
    }
  }
}

function drawFlowLines(rgba: Uint8Array, w: number, h: number,
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

function drawImpactBurst(rgba: Uint8Array, w: number, h: number, cx: number, cy: number, radius: number = 80): void {
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

// ---------- Layout procédural BSP ----------
interface BSPNode { x: number; y: number; w: number; h: number; mood: string; }

function generateBSPLayout(panelCount: number, moods: string[], pageW: number, pageH: number): PanelLayout[] {
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

// ---------- Bibliothèque de layouts (fallback) ----------
interface LayoutTemplate {
  slug: string;
  vibe: string;
  gutter: number;
  panels: PanelLayout[];
}

const LAYOUT_LIBRARY: LayoutTemplate[] = [
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

function selectLayout(layoutSlug?: string, panelCount?: number, moods?: string[]): { panels: PanelLayout[]; slug: string; gutter: number } {
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
