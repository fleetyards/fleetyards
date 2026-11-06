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

describe("models store ship section", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("opens on the key figures and remembers advanced mode", () => {
    const store = useModelsStore();

    expect(store.shipMetricsAdvanced).toBe(false);

    store.toggleShipMetricsAdvanced();

    expect(store.shipMetricsAdvanced).toBe(true);
  });

  it("keeps a hardpoint card's fold for one ship only", () => {
    const store = useModelsStore();

    store.setHardpointGroupFolds("gladius", { weapon: false });

    expect(store.hardpointGroupFold("gladius", "weapon")).toBe(false);
    expect(store.hardpointGroupFold("gladius", "system")).toBeUndefined();
    expect(store.hardpointGroupFold("carrack", "weapon")).toBeUndefined();
  });

  it("forgets a card set back, and a ship with none left", () => {
    const store = useModelsStore();

    store.setHardpointGroupFolds("gladius", { weapon: false, system: true });
    store.setHardpointGroupFolds("gladius", { weapon: undefined });

    expect(store.foldedHardpointGroups).toEqual({ gladius: { system: true } });

    store.setHardpointGroupFolds("gladius", { system: undefined });

    expect(store.foldedHardpointGroups).toEqual({});
  });
});
