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

  it("flips a hardpoint card for one ship only", () => {
    const store = useModelsStore();

    store.toggleHardpointGroup("gladius", "weapon");

    expect(store.hardpointGroupFlipped("gladius", "weapon")).toBe(true);
    expect(store.hardpointGroupFlipped("gladius", "system")).toBe(false);
    expect(store.hardpointGroupFlipped("carrack", "weapon")).toBe(false);
  });

  it("forgets a ship with every card back as it opens", () => {
    const store = useModelsStore();

    store.setFlippedHardpointGroups("gladius", ["weapon", "system"]);
    store.toggleHardpointGroup("gladius", "weapon");

    expect(store.flippedHardpointGroups).toEqual({ gladius: ["system"] });

    store.setFlippedHardpointGroups("gladius", []);

    expect(store.flippedHardpointGroups).toEqual({});
  });
});
