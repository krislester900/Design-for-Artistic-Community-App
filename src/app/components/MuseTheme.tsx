import { useState, useCallback } from "react";

export type MuseTheme = {
  id: string;
  name: string;
  background: string;
  surface: string;
  border: string;
  text: string;
  muted: string;
  accent: string;
  glow: string;
};

export const MUSE_THEMES: MuseTheme[] = [
  {
    id: "light",
    name: "Blanc",
    background: "#ffffff",
    surface: "#ffffff",
    border: "#000000",
    text: "#000000",
    muted: "#666666",
    accent: "#000000",
    glow: "rgba(0,0,0,0.08)",
  },
  {
    id: "dark",
    name: "Noir",
    background: "#000000",
    surface: "#000000",
    border: "#ffffff",
    text: "#ffffff",
    muted: "#aaaaaa",
    accent: "#ffffff",
    glow: "rgba(255,255,255,0.08)",
  },
  {
    id: "cyan",
    name: "Vert cyan",
    background: "#000000",
    surface: "#000000",
    border: "#00ffcc",
    text: "#ffffff",
    muted: "#99ffee",
    accent: "#00ffcc",
    glow: "rgba(0,255,204,0.12)",
  },
  {
    id: "rose",
    name: "Rose",
    background: "#000000",
    surface: "#000000",
    border: "#ff99cc",
    text: "#ffffff",
    muted: "#ffccdd",
    accent: "#ff99cc",
    glow: "rgba(255,153,204,0.12)",
  },
];

export function useMuseTheme() {
  const [themeId, setThemeId] = useState<string>("light");

  const theme = MUSE_THEMES.find((t) => t.id === themeId) ?? MUSE_THEMES[0];

  const cycleTheme = useCallback(() => {
    setThemeId((current) => {
      const idx = MUSE_THEMES.findIndex((t) => t.id === current);
      return MUSE_THEMES[(idx + 1) % MUSE_THEMES.length].id;
    });
  }, []);

  return { theme, themeId, cycleTheme, setThemeId };
}
