import { beforeEach, describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import { setupAppsignal } from "./Appsignal";

const defaultHandler = vi.hoisted(() => vi.fn());

vi.mock("@appsignal/javascript", () => ({
  default: class {
    sendError = vi.fn();
  },
}));

vi.mock("@appsignal/vue", () => ({
  errorHandler: () => defaultHandler,
}));

const handle = (error: Error) => {
  const app = createApp({});

  setupAppsignal(app);
  app.config.errorHandler?.(error, null, "setup function");
};

describe("setupAppsignal", () => {
  beforeEach(() => {
    defaultHandler.mockClear();
    window.APPSIGNAL_KEY = "key";
  });

  it.each([
    "THREE.WebGLRenderer: Error creating WebGL context.",
    "THREE.WebGLRenderer: Error creating WebGL context with your selected attributes.",
  ])("does not report %s", (message) => {
    handle(new Error(message));

    expect(defaultHandler).not.toHaveBeenCalled();
  });

  it("reports any other error", () => {
    handle(new Error("Cannot read properties of null"));

    expect(defaultHandler).toHaveBeenCalledOnce();
  });
});
