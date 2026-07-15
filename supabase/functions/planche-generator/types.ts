// Types partagés pour le pipeline de génération de planches manga.

export interface PanelLayout {
  x: number;
  y: number;
  w: number;
  h: number;
  label: string;
  breakFrame?: boolean;
}

export interface PanelScript {
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

export type Kps = [number, number][]; // 18 keypoints [x,y] in POSE_W×POSE_H space
export type Poseless = [number, number][]; // 18 keypoints per character [x,y] in POSE_W×POSE_H space

export type ForeshortenRule = { limb: string; scales: number[]; char?: number };

export interface Character {
  name: string;
  appearance: string;
}

export interface AdjacentPair {
  a: number;
  b: number;
  dir: "h" | "v";
  gutterX: number;
  gutterY: number;
  gutterW: number;
  gutterH: number;
}

export interface BSPNode {
  x: number;
  y: number;
  w: number;
  h: number;
  mood: string;
}

export interface LayoutTemplate {
  slug: string;
  vibe: string;
  gutter: number;
  panels: PanelLayout[];
}
