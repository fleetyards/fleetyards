import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./spec/playwright",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : 1,
  reporter: process.env.CI ? "blob" : "html",
  timeout: 120 * 1000,
  expect: { timeout: 20 * 1000 },
  globalTimeout: 60 * 60 * 1000,
  use: {
    baseURL: "http:/localhost:8280",
    trace: "on-first-retry",
    testIdAttribute: "data-test",
  },
  webServer: {
    command: "pnpm test:e2e:startserver",
    url: "http://localhost:8280/health_check",
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    stderr: "pipe",
  },
});
