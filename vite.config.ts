import { defineConfig, splitVendorChunkPlugin } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { createVuePlugin as Vue2Plugin } from 'vite-plugin-vue2'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  base: 'vite',
  plugins: [
    RubyPlugin(),
    Vue2Plugin(),
    VitePWA({
      registerType: 'autoUpdate',
      filename: 'sw.js',
      useCredentials: true,
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg}'],
        clientsClaim: true,
        skipWaiting: true,
        navigateFallback: null,
      },
    }),
    splitVendorChunkPlugin(),
  ],
  build: {
    rollupOptions: {
      maxParallelFileReads: 4,
    },
    commonjsOptions: {
      requireReturnsDefault: true,
    },
  },
  define: {
    'process.env': {},
  },
})
