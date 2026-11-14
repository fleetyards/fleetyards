import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useWebpCheck } from "./useWebpCheck";
import { useWebpStore } from "@/shared/stores/webp";

const fakeImage = (outcome: "load" | "error", width = 1) =>
  class {
    width = 0;
    height = 0;
    onload: (() => void) | null = null;
    onerror: (() => void) | null = null;

    set src(_value: string) {
      queueMicrotask(() => {
        if (outcome === "load") {
          this.width = width;
          this.height = width;
          this.onload?.();
        } else {
          this.onerror?.();
        }
      });
    }
  };

describe("useWebpCheck", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("reports support when the browser decodes the pixel", async () => {
    vi.stubGlobal("Image", fakeImage("load"));

    expect(await useWebpCheck().check()).toBe(true);
    expect(useWebpStore().supported).toBe(true);
  });

  it("reports no support when the pixel fails to decode", async () => {
    vi.stubGlobal("Image", fakeImage("error"));

    expect(await useWebpCheck().check()).toBe(false);
    expect(useWebpStore().supported).toBe(false);
  });

  it("reports no support when the pixel decodes to nothing", async () => {
    vi.stubGlobal("Image", fakeImage("load", 0));

    expect(await useWebpCheck().check()).toBe(false);
  });

  it("needs no createImageBitmap", async () => {
    vi.stubGlobal("Image", fakeImage("load"));
    vi.stubGlobal("createImageBitmap", undefined);

    expect(await useWebpCheck().check()).toBe(true);
  });
});
