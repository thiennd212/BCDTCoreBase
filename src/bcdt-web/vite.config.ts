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
  build: {
    // Perf-15: tách Fortune Sheet thành vendor chunk riêng để cache hiệu quả
    // Fortune Sheet ~4.2MB là inherent cost của Excel-like editor, cần isolate để user
    // không phải re-download khi code app thay đổi
    chunkSizeWarningLimit: 5000,
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-fortune': ['@fortune-sheet/react', '@fortune-sheet/core'],
          'vendor-fortune-excel': ['@corbe30/fortune-excel'],
        },
      },
    },
  },
})
