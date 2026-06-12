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
  plugins: [
    figmaAssetResolver(),
    // The React and Tailwind plugins are both required for Make, even if
    // Tailwind is not being actively used – do not remove them
    react(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      // Alias @ to the src directory
      '@': path.resolve(__dirname, './src'),
    },
  },

  // Multi-Page App (MPA) configuration
  // Each HTML file is an entry point so Vite bundles its scripts correctly
  build: {
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
      },
    },
  },

  // File types to support raw imports. Never add .css, .tsx, or .ts files to this.
  assetsInclude: ['**/*.svg', '**/*.csv'],
})
