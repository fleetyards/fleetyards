import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { createVuePlugin } from 'vite-plugin-vue2'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    createVuePlugin(),
    RubyPlugin(),
    VitePWA({
      registerType: 'autoUpdate',
      workbox: {
        clientsClaim: true,
        skipWaiting: true,
      },
    }),
  ],
  define: {
    'process.env': {},
  },
})
