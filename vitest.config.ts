/// <reference types="vitest" />
import { defineConfig } from "vitest/config";

import viteConfig from "./vite.config.ts";

export default defineConfig({
  ...viteConfig,
  test: {
    globals: true,
    environment: "jsdom",
  },
});
