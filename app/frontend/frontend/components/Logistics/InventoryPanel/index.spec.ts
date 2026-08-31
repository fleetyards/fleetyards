import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";

const enabledFeatures = vi.hoisted(() => ({ value: [] as string[] }));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (feature: string) =>
      enabledFeatures.value.includes(feature),
  }),
}));

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

beforeEach(() => {
  enabledFeatures.value = ["tools_cargo_grids"];
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

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: "/tools/cargo-grids",
      name: "cargo-grids",
      component: { template: "<div />" },
    },
  ],
});

const mount = (record: InventoryPanelRecord) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { inventory: record, to: "/hangar/inventories" },
    plugins: [router],
  });

const shipInventory = (
  overrides: Partial<InventoryPanelRecord> = {},
): InventoryPanelRecord =>
  inventory({
    totalVolumeScu: 12,
    vehicle: {
      id: "v1",
      name: "Ironclad",
      model: { slug: "ironclad", cargo: 400 },
    },
    ...overrides,
  });

const cargoGridsLink = "[data-test='inventory-panel-cargo-grids']";

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

  it("opens the viewer on the ship and the load it carries", async () => {
    const wrapper = await mount(shipInventory());

    const link = wrapper.find(cargoGridsLink);

    expect(link.exists()).toBe(true);

    const href = decodeURIComponent(link.attributes("href") || "");

    expect(href).toContain("ship=ironclad");
    expect(href).toContain("containers=8x1,4x1");
  });

  it("waits for a full SCU before offering the viewer", async () => {
    const wrapper = await mount(shipInventory({ totalVolumeScu: 0.4 }));

    expect(wrapper.find(cargoGridsLink).exists()).toBe(false);
  });

  // A hold the viewer cannot draw, and a tool the viewer cannot reach, both
  // leave the link pointing at nothing.
  it("keeps the viewer to ships with a grid and the feature on", async () => {
    const gridless = await mount(
      shipInventory({
        vehicle: { id: "v1", name: "Vulture", model: { slug: "vulture" } },
      }),
    );

    expect(gridless.find(cargoGridsLink).exists()).toBe(false);

    enabledFeatures.value = [];

    const disabled = await mount(shipInventory());

    expect(disabled.find(cargoGridsLink).exists()).toBe(false);
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
