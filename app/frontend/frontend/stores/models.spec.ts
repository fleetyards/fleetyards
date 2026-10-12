import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useModelsStore } from "./models";

describe("models store sections", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("closes a section for one model only", () => {
    const store = useModelsStore();

    store.toggleSection("andromeda", "paints");

    expect(store.sectionCollapsed("andromeda", "paints")).toBe(true);
    expect(store.sectionCollapsed("andromeda", "modules")).toBe(false);
    expect(store.sectionCollapsed("taurus", "paints")).toBe(false);
  });

  it("opens it again and forgets a model with nothing closed", () => {
    const store = useModelsStore();

    store.toggleSection("andromeda", "paints");
    store.toggleSection("andromeda", "paints");

    expect(store.sectionCollapsed("andromeda", "paints")).toBe(false);
    expect(store.collapsedSections).toEqual({});
  });
});
