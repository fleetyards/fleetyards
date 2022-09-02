import path from 'path'
import { defineConfig } from 'vitest/config'
import Vue2Plugin from '@vitejs/plugin-vue2'

export default defineConfig({
  plugins: [Vue2Plugin()],
  define: {
    'process.env': {},
  },
  test: {
    include: ['app/frontend/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    globals: true,
    environment: 'jsdom',
    alias: [{ find: /^vue$/, replacement: 'vue/dist/vue.runtime.common.js' }],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './app/frontend'),
      '~': path.resolve(__dirname, '.'),
    },
  },
})
