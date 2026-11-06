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

  it("expands a hardpoint card for one ship only", () => {
    const store = useModelsStore();

    store.toggleHardpointGroup("gladius", "weapon");

    expect(store.hardpointGroupExpanded("gladius", "weapon")).toBe(true);
    expect(store.hardpointGroupExpanded("gladius", "system")).toBe(false);
    expect(store.hardpointGroupExpanded("carrack", "weapon")).toBe(false);
  });

  it("forgets a ship with every card back on its summary", () => {
    const store = useModelsStore();

    store.setExpandedHardpointGroups("gladius", ["weapon", "system"]);
    store.toggleHardpointGroup("gladius", "weapon");

    expect(store.expandedHardpointGroups).toEqual({ gladius: ["system"] });

    store.setExpandedHardpointGroups("gladius", []);

    expect(store.expandedHardpointGroups).toEqual({});
  });
});
