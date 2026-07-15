// Traitement d'image bas niveau + primitives de dessin manga (bitmap font 8x8).
// Module pur (aucun effet de bord) → testable isolément.

import { PanelLayout } from "../types.ts";

export const COMPOSITE_W = 2400;
export const COMPOSITE_H = 3400;

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

export function pngEncode(w: number, h: number, rgba: Uint8Array): Uint8Array {
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

export async function pngDecode(buf: ArrayBuffer): Promise<{width: number; height: number; rgba: Uint8Array}> {
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

export function bilinearResize(src: Uint8Array, sw: number, sh: number, dw: number, dh: number): Uint8Array {
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

// ============================================================
// BITMAP FONT (8x8) — Public Domain X11 font, ASCII 32-126
// ============================================================
export const FONT8X8 = new Uint8Array([
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

export const FONT_W = 8;
export const FONT_H = 8;

export function renderTextOnPage(page: Uint8Array, pw: number, ph: number, text: string, px: number, py: number, scale: number, fg: number, bg: number) {
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

export function textWidth(text: string, scale: number): number {
  return text.length * FONT_W * scale;
}

export function textHeight(scale: number): number {
  return FONT_H * scale;
}

export function drawEllipse(page: Uint8Array, pw: number, ph: number, cx: number, cy: number, rx: number, ry: number, fill: number, stroke: number) {
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

export function drawLine(page: Uint8Array, pw: number, ph: number, x1: number, y1: number, x2: number, y2: number, color: number) {
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

export function drawMangaSpeechBubble(page: Uint8Array, pw: number, ph: number,
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

export function drawThickLine(rgba: Uint8Array, w: number, h: number,
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
