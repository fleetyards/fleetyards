import { describe, it, expect, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import {
  DEFAULT_FLEETCHART_OPTIONS,
  FleetchartGroups,
  FleetchartLayouts,
  FleetchartModes,
  FleetchartViewpoints,
  useFleetchartStore,
} from "./fleetchart";

describe("fleetchart store", () => {
  beforeEach(() => setActivePinia(createPinia()));

  it("merges changed options over the defaults, per chart", () => {
    const store = useFleetchartStore();
    store.updateOptions({
      namespace: "hangar",
      options: { group: FleetchartGroups.STATUS },
    });
    store.updateOptions({ namespace: "hangar", options: { scaleBar: true } });

    expect(store.fleetchartOptions("hangar")).toEqual({
      ...DEFAULT_FLEETCHART_OPTIONS,
      group: FleetchartGroups.STATUS,
      scaleBar: true,
    });
    expect(store.fleetchartOptions("fleet")).toEqual(
      DEFAULT_FLEETCHART_OPTIONS,
    );
  });

  it("keeps placements per chart", () => {
    const store = useFleetchartStore();
    store.updatePlacements({
      namespace: "hangar",
      placements: { a: { x: 1, y: 2 } },
    });

    expect(store.fleetchartPlacements("hangar")).toEqual({ a: { x: 1, y: 2 } });
    expect(store.fleetchartPlacements("fleet")).toEqual({});
  });

  it("starts packed", () => {
    const store = useFleetchartStore();

    expect(store.fleetchartLayout("hangar")).toBe(FleetchartLayouts.PACKED);
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

    expect(store.fleetchartLayout("hangar")).toBe(FleetchartLayouts.PACKED);

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
