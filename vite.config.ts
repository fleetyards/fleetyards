import { resolve } from "path";
import { defineConfig } from "vite";
import ViteRails from "vite-plugin-rails";
import Vue from "@vitejs/plugin-vue";
import tailwindcss from "tailwindcss";
import { VitePWA } from "vite-plugin-pwa";
import Components from "unplugin-vue-components/vite";
import AutoImport from "unplugin-auto-import/vite";
import browserslistToEsbuild from "browserslist-to-esbuild";
import { templateCompilerOptions } from "@tresjs/core";

const cache: { [key: string]: string } = {};

export const accessEnv = (key: string, defaultValue?: string): string => {
  if (cache[key]) return cache[key];

  if (!(key in process.env) || process.env[key] === undefined) {
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
    ViteRails(),
    Vue({
      ...templateCompilerOptions,
    }),
    VitePWA({
      registerType: "autoUpdate",
      filename: "sw.js",
      useCredentials: true,
      scope: "/",
      manifest: {
        name: "My Awesome App",
        short_name: "MyApp",
        description: "My Awesome App description",
        theme_color: "#ffffff",
        icons: [
          {
            src: "pwa-192x192.png",
            sizes: "192x192",
            type: "image/png",
          },
          {
            src: "pwa-512x512.png",
            sizes: "512x512",
            type: "image/png",
          },
        ],
      },
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
    Components({
      // generate `components.d.ts` global declarations
      // https://github.com/antfu/unplugin-vue-components#typescript
      dts: true,
      directoryAsNamespace: true,
      types: [
        {
          from: "vue-router",
          names: ["RouterLink", "RouterView"],
        },
      ],
      // relative paths to the directory to search for components.
      dirs: ["shared/components/base"],
    }),
    AutoImport({
      dts: true,
      // fix eslint complaining about missing imports
      eslintrc: {
        enabled: true,
      },
      imports: ["vue", "vitest", "vue-router"],
    }),
  ],
  resolve: {
    alias: {
      "@": resolve(__dirname, "app/frontend"),
    },
  },
  build: {
    target: browserslistToEsbuild(),
    minify: "esbuild",
    emptyOutDir: false,
    rollupOptions: {
      maxParallelFileOps: 5,
      output: {
        manualChunks: {
          vue: ["vue"],
          "vue-router": ["vue-router"],
        },
      },
    },
    commonjsOptions: {
      requireReturnsDefault: true,
    },
  },
  server: {
    cors: true,
    fs: {
      allow: [".", accessEnv("FLEETYARDS_NODE_MODULES", "node_modules")],
    },
    hmr: {
      timeout: 60000,
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "@/stylesheets/variables.scss";`,
      },
    },
  },
  define: {
    "process.env": {},
    "import.meta.env.__VUE_PROD_HYDRATION_MISMATCH_DETAILS__": JSON.stringify(
      process.env.__VUE_PROD_HYDRATION_MISMATCH_DETAILS__,
    ),
    "import.meta.env.__VUE_OPTIONS_API__": JSON.stringify(
      process.env.__VUE_OPTIONS_API__,
    ),
  },
  cacheDir: accessEnv("FLEETYARDS_VITE_CACHE", "node_modules/.vite"),
});
