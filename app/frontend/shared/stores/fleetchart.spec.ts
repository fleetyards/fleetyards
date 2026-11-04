import { describe, it, expect, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import {
  FleetchartLayouts,
  FleetchartModes,
  FleetchartViewpoints,
  useFleetchartStore,
} from "./fleetchart";

describe("fleetchart store", () => {
  beforeEach(() => setActivePinia(createPinia()));

  it("starts in columns", () => {
    const store = useFleetchartStore();

    expect(store.fleetchartLayout("hangar")).toBe(FleetchartLayouts.COLUMNS);
  });

  it("reads a persisted classic mode as the classic layout", () => {
    const store = useFleetchartStore();
    store.updateMode({ namespace: "hangar", mode: FleetchartModes.CLASSIC });

    expect(store.fleetchartLayout("hangar")).toBe(FleetchartLayouts.CLASSIC);
  });

  it("reads a persisted panzoom mode as the columns layout", () => {
    const store = useFleetchartStore();
    store.updateMode({ namespace: "hangar", mode: FleetchartModes.PANZOOM });

    expect(store.fleetchartLayout("hangar")).toBe(FleetchartLayouts.COLUMNS);
  });

  it("prefers a chosen layout over a persisted mode", () => {
    const store = useFleetchartStore();
    store.updateMode({ namespace: "hangar", mode: FleetchartModes.CLASSIC });
    store.updateLayout({
      namespace: "hangar",
      layout: FleetchartLayouts.COLUMNS,
    });

    expect(store.fleetchartLayout("hangar")).toBe(FleetchartLayouts.COLUMNS);
  });

  it("copes with state persisted before layouts existed", () => {
    const store = useFleetchartStore();
    store.$patch((state) => {
      (state as { layout?: unknown }).layout = undefined;
    });

    expect(store.fleetchartLayout("hangar")).toBe(FleetchartLayouts.COLUMNS);

    store.updateLayout({
      namespace: "hangar",
      layout: FleetchartLayouts.CLASSIC,
    });

    expect(store.fleetchartLayout("hangar")).toBe(FleetchartLayouts.CLASSIC);
  });

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
