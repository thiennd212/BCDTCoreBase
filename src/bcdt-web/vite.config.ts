import { defineConfig, type PluginOption } from 'vite'
import react from '@vitejs/plugin-react'
import { visualizer } from 'rollup-plugin-visualizer'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    // Perf-14: bundle analysis – sau build mở dist/stats.html (hoặc bcdt-web/stats.html) để xem treemap/sunburst
    visualizer({ filename: 'dist/stats.html', open: false, gzipSize: true }) as PluginOption,
  ],
  server: {
    port: 5173,
    proxy: {
      '/api': { target: 'http://localhost:5080', changeOrigin: true },
    },
  },
})
