import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { createVuePlugin as Vue2Plugin } from 'vite-plugin-vue2'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    Vue2Plugin(),
    VitePWA({
      registerType: 'autoUpdate',
      filename: 'sw.js',
      useCredentials: true,
      workbox: {
        clientsClaim: true,
        skipWaiting: true,
        navigateFallback: null,
      },
    }),
  ],
  build: {
    commonjsOptions: {
      requireReturnsDefault: true,
    },
  },
  define: {
    'process.env': {},
  },
})
