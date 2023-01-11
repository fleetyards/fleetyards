import { defineConfig, splitVendorChunkPlugin } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import Vue2Plugin from "@vitejs/plugin-vue2";
import { VitePWA } from "vite-plugin-pwa";

const cache: { [key: string]: string } = {};

export const accessEnv = (key: string, defaultValue?: string): string => {
  if (cache[key]) return cache[key];

  if (!(key in process.env) || typeof process.env[key] === undefined) {
    if (defaultValue) return defaultValue;
    throw new Error(`${key} not found in process.env!`);
  }

  if (!(key in cache)) {
    cache[key] = <string>process.env[key];
  }

  return cache[key];
};

export default defineConfig({
  plugins: [
    RubyPlugin(),
    Vue2Plugin(),
    VitePWA({
      registerType: "autoUpdate",
      filename: "sw.js",
      useCredentials: true,
      scope: "/",
      workbox: {
        modifyURLPrefix: {
          "": "/vite/",
        },
        globPatterns: ["**/*.{js,css,html,ico,png,svg}"],
        clientsClaim: true,
        skipWaiting: true,
        navigateFallback: null,
      },
    }),
    splitVendorChunkPlugin(),
  ],
  build: {
    rollupOptions: {
      maxParallelFileReads: 5,
    },
    commonjsOptions: {
      requireReturnsDefault: true,
    },
  },
  server: {
    fs: {
      allow: [".", accessEnv("FLEETYARDS_NODE_MODULES", "node_modules")],
    },
  },
  define: {
    "process.env": {},
  },
  cacheDir: accessEnv("FLEETYARDS_VITE_CACHE", "node_modules/.vite"),
});
