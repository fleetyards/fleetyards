import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./overview.vue";
import { type Vehicle, BoughtViaEnum } from "@/services/fyApi";

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

vi.mock("@/shared/components/ViewImage/index.vue", () => ({
  default: { name: "ViewImage", props: ["image", "alt"], template: "<div />" },
}));

const NOW = "2026-10-12T12:00:00Z";

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    name: "Pathfinder",
    serial: "PF-01",
    boughtVia: BoughtViaEnum.PLEDGE_STORE,
    boughtViaLabel: "Pledge Store",
    wanted: false,
    flagship: false,
    alternativeNames: [],
    hangarGroupIds: [],
    hangarGroups: [],
    loaner: false,
    bundled: false,
    modelModuleIds: [],
    modelUpgradeIds: [],
    nameVisible: false,
    public: false,
    saleNotify: false,
    logEntriesPublicByDefault: false,
    model: {
      id: "model-1",
      name: "Carrack",
      slug: "carrack",
      media: {},
      manufacturer: { id: "manufacturer-1", name: "Anvil", slug: "anvil" },
    },
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  }) as Vehicle;

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "hangar", component: { template: "<div />" } },
    { path: "/ships/:slug", name: "ship", component: { template: "<div />" } },
  ],
});

const mount = (props: { vehicle: Vehicle }) =>
  mountWithDefaults(Component, { props, plugins: [router] });

const settingKeys = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper
    .findAll('[data-test^="vehicle-setting-"]')
    .map((setting) => setting.attributes("data-test"));

describe("HangarVehicleOverviewPage", () => {
  it("lists what the ship is", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    expect(wrapper.find('[data-test="vehicle-fact-name"]').text()).toContain(
      "Pathfinder",
    );
    expect(wrapper.find('[data-test="vehicle-fact-serial"]').text()).toContain(
      "PF-01",
    );
    expect(
      wrapper.find('[data-test="vehicle-fact-boughtVia"]').text(),
    ).toContain("Pledge Store");
    expect(wrapper.find('[data-test="vehicle-fact-paint"]').exists()).toBe(
      false,
    );
  });

  it("shows the switches the owner turned on", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ flagship: true, public: true }),
    });

    expect(settingKeys(wrapper)).toEqual([
      "vehicle-setting-flagship",
      "vehicle-setting-public",
    ]);
  });

  it("leaves sale alerts out for a ship already in the hangar", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ saleNotify: true, wanted: false }),
    });

    expect(settingKeys(wrapper)).toEqual([]);
  });

  it("shows sale alerts for a ship on the wishlist", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ saleNotify: true, wanted: true }),
    });

    expect(settingKeys(wrapper)).toEqual(["vehicle-setting-saleNotify"]);
  });

  it("offers no picture or edit for a loaner", async () => {
    const wrapper = await mount({ vehicle: vehicle({ loaner: true }) });

    expect(wrapper.find('[data-test="vehicle-image-edit"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="vehicle-overview-edit"]').exists()).toBe(
      false,
    );
  });
});
