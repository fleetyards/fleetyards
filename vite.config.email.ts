import { resolve } from "path";
import { defineConfig } from "vite";

export default defineConfig({
  root: resolve(__dirname, "app/frontend"),
  publicDir: false,
  build: {
    outDir: resolve(__dirname, "public/vite-test"),
    emptyOutDir: false,
    manifest: true,
    rolldownOptions: {
      input: {
        "entrypoints/email": resolve(
          __dirname,
          "app/frontend/entrypoints/email.scss",
        ),
      },
    },
    assetsDir: "assets",
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "${resolve(__dirname, "app/frontend/stylesheets/variables.scss")}";`,
      },
    },
  },
});
