import { defineConfig } from "cypress";

export default defineConfig({
  projectId: "vngu15",
  video: false,
  videoCompression: 0,
  viewportWidth: 2560,
  viewportHeight: 1440,
  defaultCommandTimeout: 30000,
  pageLoadTimeout: 120000,
  e2e: {
    baseUrl: "http://fleetyards.test",
  },
});
