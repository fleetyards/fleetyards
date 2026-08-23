import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeAll, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";

// The panel carries a background image, and jsdom has no IntersectionObserver
// for useLazyBackground to hand it to.
beforeAll(() => {
  vi.stubGlobal(
    "IntersectionObserver",
    class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  );
});

const inventory = (
  overrides: Partial<InventoryPanelRecord> = {},
): InventoryPanelRecord => ({
  id: "1",
  name: "Ironclad Inventory",
  slug: "ironclad-inventory",
  entriesCount: 3,
  totalScu: 312,
  ...overrides,
});

const mount = (record: InventoryPanelRecord) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { inventory: record, to: "/hangar/inventories" },
  });

describe("InventoryPanel", () => {
  it("names the ship an inventory rides in", async () => {
    const wrapper = await mount(
      inventory({
        location: "Port Olisar",
        vehicle: { id: "v1", name: "Rustbucket" },
      }),
    );

    expect(wrapper.text()).toContain("Rustbucket");
    expect(wrapper.text()).not.toContain("Port Olisar");
  });

  it("falls back to the location without a ship", async () => {
    const wrapper = await mount(inventory({ location: "Port Olisar" }));

    expect(wrapper.text()).toContain("Port Olisar");
  });

  it("reports stock against the ship's cargo capacity", async () => {
    const wrapper = await mount(
      inventory({
        vehicle: { id: "v1", name: "Ironclad", model: { cargo: 400 } },
      }),
    );

    expect(wrapper.text()).toContain("312 / 400 SCU");
    expect(wrapper.find(".inventory-panel-count-over").exists()).toBe(false);
  });

  it("flags an overfilled hold without hiding the numbers", async () => {
    const wrapper = await mount(
      inventory({
        totalScu: 460,
        vehicle: { id: "v1", name: "Ironclad", model: { cargo: 400 } },
      }),
    );

    expect(wrapper.find(".inventory-panel-count-over").exists()).toBe(true);
    expect(wrapper.text()).toContain("460 / 400 SCU");
  });
});
