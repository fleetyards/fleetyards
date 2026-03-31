import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./spec/playwright",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? "blob" : "html",
  timeout: 60 * 1000,
  expect: { timeout: 10 * 1000 },
  globalTimeout: 60 * 60 * 1000,
  use: {
    baseURL: "http://localhost:8280",
    trace: "on-first-retry",
    testIdAttribute: "data-test",
  },
  webServer: [
    ...(!process.env.CI
      ? [
          {
            command: "RAILS_ENV=test pnpm dev:vite",
            url: "http://127.0.0.1:3137/vite-test/@vite/client",
            reuseExistingServer: true,
            stdout: "pipe" as const,
            stderr: "pipe" as const,
          },
        ]
      : []),
    {
      command: "pnpm test:e2e:startserver",
      url: "http://localhost:8280/health_check",
      reuseExistingServer: !process.env.CI,
      stdout: "pipe",
      stderr: "pipe",
    },
  ],
});
