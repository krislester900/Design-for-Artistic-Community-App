import { defineConfig, type Plugin } from "vite";
import path from "path";
import fs from "fs";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";

// Injects index.html into dist after build (Capacitor requires it)
function capacitorHtmlPlugin(): Plugin {
  return {
    name: "capacitor-html",
    closeBundle() {
      const html = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
    <meta name="theme-color" content="#000000" />
    <title>iPod CoverFlow</title>
    <link rel="stylesheet" href="./assets/main.css" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="./assets/main.js"></script>
  </body>
</html>`;
      fs.writeFileSync(path.resolve(__dirname, "dist/index.html"), html);
    },
  };
}

export default defineConfig({
  plugins: [react(), tailwindcss(), capacitorHtmlPlugin()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src/app"),
    },
  },
  build: {
    outDir: "dist",
    assetsDir: "assets",
    sourcemap: false,
    rollupOptions: {
      input: "src/main.tsx",
      output: {
        entryFileNames: "assets/main.js",
        chunkFileNames: "assets/[name]-[hash].js",
        assetFileNames: "assets/[name][extname]",
        manualChunks: {
          vendor: ["react", "react-dom"],
          motion: ["motion/react"],
        },
      },
    },
  },
  base: "./",
});
