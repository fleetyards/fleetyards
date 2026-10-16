import { describe, it, expect, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { FleetchartViewpoints, useFleetchartStore } from "./fleetchart";

describe("fleetchart store", () => {
  beforeEach(() => setActivePinia(createPinia()));

  it("shows a fleetchart from port until somebody chooses", () => {
    const store = useFleetchartStore();

    expect(store.fleetchartViewpoint("hangar")).toBe(FleetchartViewpoints.PORT);
  });

  it("reads a persisted side viewpoint as port", () => {
    const store = useFleetchartStore();
    store.$patch({
      viewpoint: { hangar: "side" as FleetchartViewpoints },
    });

    expect(store.fleetchartViewpoint("hangar")).toBe(FleetchartViewpoints.PORT);
  });

  it("keeps a chosen viewpoint", () => {
    const store = useFleetchartStore();
    store.updateViewpoint({
      namespace: "hangar",
      viewpoint: FleetchartViewpoints.TOP,
    });

    expect(store.fleetchartViewpoint("hangar")).toBe(FleetchartViewpoints.TOP);
  });
});
