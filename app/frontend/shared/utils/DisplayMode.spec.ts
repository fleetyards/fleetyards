import { afterEach, describe, expect, it, vi } from "vitest";
import { isInstalledApp } from "./DisplayMode";

const stubDisplayMode = (standalone: boolean) =>
  vi.stubGlobal(
    "matchMedia",
    vi.fn(() => ({ matches: standalone }) as MediaQueryList),
  );

describe("isInstalledApp", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    Reflect.deleteProperty(navigator, "standalone");
  });

  it("is true when the page runs in standalone display mode", () => {
    stubDisplayMode(true);

    expect(isInstalledApp()).toBe(true);
  });

  it("is true for an iOS Home Screen app", () => {
    stubDisplayMode(false);
    Object.defineProperty(navigator, "standalone", {
      value: true,
      configurable: true,
    });

    expect(isInstalledApp()).toBe(true);
  });

  it("is false in a browser tab", () => {
    stubDisplayMode(false);

    expect(isInstalledApp()).toBe(false);
  });

  it("is false when the display-mode query throws", () => {
    vi.stubGlobal(
      "matchMedia",
      vi.fn(() => {
        throw new Error("unsupported");
      }),
    );

    expect(isInstalledApp()).toBe(false);
  });
});
