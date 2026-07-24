import { defineConfig } from 'vite'
import path from 'path'
import { fileURLToPath } from 'url'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

function figmaAssetResolver() {
  return {
    name: 'figma-asset-resolver',
    resolveId(id) {
      if (id.startsWith('figma:asset/')) {
        const filename = id.replace('figma:asset/', '')
        return path.resolve(__dirname, 'src/assets', filename)
      }
    },
  }
}

export default defineConfig({
  base: './',
  plugins: [
    figmaAssetResolver(),
    react(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },

  build: {
    sourcemap: false,
    minify: 'terser',
    rollupOptions: {
      input: {
        main: path.resolve(__dirname, 'index.html'),
        connexion: path.resolve(__dirname, 'connexion.html'),
        inscription: path.resolve(__dirname, 'inscription.html'),
        music: path.resolve(__dirname, 'music.html'),
        'art-visuel': path.resolve(__dirname, 'art-visuel.html'),
        manga: path.resolve(__dirname, 'manga.html'),
        films: path.resolve(__dirname, 'films.html'),
        litterature: path.resolve(__dirname, 'litterature.html'),
        animation: path.resolve(__dirname, 'animation.html'),
        community: path.resolve(__dirname, 'community.html'),
        database: path.resolve(__dirname, 'database.html'),
        profil: path.resolve(__dirname, 'profil.html'),
        admin: path.resolve(__dirname, 'admin.html'),
        training: path.resolve(__dirname, 'training.html'),
      },
      output: {
        manualChunks(id) {
          if (id.includes('node_modules/react-dom') || id.includes('node_modules/react/') || id.includes('node_modules/motion') || id.includes('node_modules/framer-motion') || id.includes('node_modules/scheduler')) {
            return 'vendor';
          }
          if (id.includes('node_modules/lucide-react') || id.includes('node_modules/clsx') || id.includes('node_modules/tailwind-merge')) {
            return 'ui';
          }
          if (id.includes('node_modules/supabase') || id.includes('node_modules/@supabase')) {
            return 'supabase';
          }
        },
      },
    },
    cssCodeSplit: true,
    target: 'es2020',
  },

  assetsInclude: ['**/*.svg', '**/*.csv'],

  server: {
    host: true,
    port: 5173,
  },
})