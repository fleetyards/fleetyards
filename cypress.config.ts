import { defineConfig } from "cypress";

export default defineConfig({
  projectId: "vngu15",
  video: false,
  videoUploadOnPasses: false,
  videoCompression: 0,
  viewportWidth: 2560,
  viewportHeight: 1440,
  defaultCommandTimeout: 10000,
  e2e: {
    baseUrl: "http://fleetyards.test",
  },
});
