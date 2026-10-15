import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./overview.vue";
import { type Vehicle, BoughtViaEnum } from "@/services/fyApi";

const shipInventoriesEnabled = ref(false);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: () => shipInventoriesEnabled.value,
  }),
}));

// The cards fetch their own data; this spec is about which of them the page
// offers for a ship, so each one is a marker.
const { stubCard } = vi.hoisted(() => ({
  stubCard: (name: string) => ({
    default: {
      name,
      props: ["vehicle", "fleets", "model", "readonly"],
      template: "<div />",
    },
  }),
}));

vi.mock("@/frontend/components/Vehicles/Overview/AcquireCard/index.vue", () =>
  stubCard("AcquireCard"),
);
vi.mock("@/frontend/components/Vehicles/Overview/LogCard/index.vue", () =>
  stubCard("LogCard"),
);
vi.mock("@/frontend/components/Vehicles/Overview/CargoCard/index.vue", () =>
  stubCard("CargoCard"),
);
vi.mock("@/frontend/components/Vehicles/Overview/LoadoutsCard/index.vue", () =>
  stubCard("LoadoutsCard"),
);
vi.mock("@/frontend/components/Vehicles/Overview/PaintsCard/index.vue", () =>
  stubCard("PaintsCard"),
);
vi.mock(
  "@/frontend/components/Vehicles/Overview/VisibilityCard/index.vue",
  () => stubCard("VisibilityCard"),
);

const NOW = "2026-10-12T12:00:00Z";

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    name: "Rust Bucket",
    serial: "IC-021",
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
    modelPaintIds: [],
    nameVisible: false,
    public: false,
    saleNotify: false,
    logEntriesPublicByDefault: false,
    model: {
      id: "model-1",
      name: "Ironclad",
      slug: "ironclad",
      inGame: true,
      media: {},
      metrics: { length: 123, cargo: 1440 },
      speeds: { scmSpeed: 115 },
      crew: { value: 4, label: "2 - 6" },
      manufacturer: { id: "manufacturer-1", name: "Drake", slug: "drake" },
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
    {
      path: "/fleets/:slug",
      name: "fleet",
      component: { template: "<div />" },
    },
  ],
});

const mount = (props: { vehicle: Vehicle }) =>
  mountWithDefaults(Component, { props, plugins: [router] });

describe("HangarVehicleOverviewPage", () => {
  it("offers loadouts for a ship in the game, and cargo once inventories are on", async () => {
    shipInventoriesEnabled.value = true;

    const wrapper = await mount({ vehicle: vehicle() });

    expect(wrapper.findComponent({ name: "LoadoutsCard" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "CargoCard" }).exists()).toBe(true);

    shipInventoriesEnabled.value = false;
  });

  it("hands a wishlist ship's log and cargo over read-only", async () => {
    shipInventoriesEnabled.value = true;

    const wrapper = await mount({ vehicle: vehicle({ wanted: true }) });

    expect(wrapper.findComponent({ name: "LogCard" }).props("readonly")).toBe(
      true,
    );
    expect(wrapper.findComponent({ name: "CargoCard" }).props("readonly")).toBe(
      true,
    );

    shipInventoriesEnabled.value = false;
  });

  it("shows the ways to get a ship only while it is on the wishlist", async () => {
    const wanted = await mount({ vehicle: vehicle({ wanted: true }) });
    const owned = await mount({ vehicle: vehicle() });

    expect(wanted.findComponent({ name: "AcquireCard" }).exists()).toBe(true);
    expect(owned.findComponent({ name: "AcquireCard" }).exists()).toBe(false);
  });

  it("offers neither for a ship not yet in the game", async () => {
    const base = vehicle();
    const wrapper = await mount({
      vehicle: { ...base, model: { ...base.model, inGame: false } },
    });

    expect(wrapper.findComponent({ name: "LoadoutsCard" }).exists()).toBe(
      false,
    );
    expect(wrapper.findComponent({ name: "CargoCard" }).exists()).toBe(false);
  });

  it("lists the fleets the ship serves in", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        fleets: [
          { id: "fleet-1", fid: "DUSK", name: "Dusk Haulers", slug: "dusk" },
        ],
      }),
    });

    expect(
      wrapper.find('[data-test="vehicle-overview-fleets"]').text(),
    ).toContain("Dusk Haulers");
  });

  it("counts the paints the ship owns", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ modelPaintIds: ["paint-1", "paint-2"] }),
    });

    expect(wrapper.find('[data-test="vehicle-fact-paint"]').text()).toContain(
      "2 paints",
    );
  });

  const sideCards = (wrapper: Awaited<ReturnType<typeof mount>>) =>
    wrapper
      .findAll(".vehicle-overview__side > [data-test]")
      .map((card) => card.attributes("data-test"));

  it("puts a dedicated ship's plaque at the top of the side column", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ dedication: "To boldly go" }),
    });

    expect(sideCards(wrapper)[0]).toBe("vehicle-overview-plaque");
  });

  it("puts the plaque invitation at the top of the side column too", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    expect(sideCards(wrapper)[0]).toBe("vehicle-overview-plaque");
  });

  it("shows a wishlist ship's plaque without a way to edit it", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ wanted: true, dedication: "To boldly go" }),
    });

    expect(wrapper.find('[data-test="vehicle-overview-plaque"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="vehicle-plaque-edit"]').exists()).toBe(
      false,
    );
  });

  it("invites no plaque for a wishlist ship without one", async () => {
    const wrapper = await mount({ vehicle: vehicle({ wanted: true }) });

    expect(wrapper.find('[data-test="vehicle-overview-plaque"]').exists()).toBe(
      false,
    );
  });

  it("leaves the configuration card off a wishlist ship", async () => {
    const wanted = await mount({ vehicle: vehicle({ wanted: true }) });
    const owned = await mount({ vehicle: vehicle() });

    expect(
      wanted.find('[data-test="vehicle-overview-configuration"]').exists(),
    ).toBe(false);
    expect(
      owned.find('[data-test="vehicle-overview-configuration"]').exists(),
    ).toBe(true);
  });

  it("leaves the visibility card off a wishlist ship", async () => {
    const wanted = await mount({ vehicle: vehicle({ wanted: true }) });
    const owned = await mount({ vehicle: vehicle() });

    expect(wanted.findComponent({ name: "VisibilityCard" }).exists()).toBe(
      false,
    );
    expect(owned.findComponent({ name: "VisibilityCard" }).exists()).toBe(true);
  });

  it("offers no plaque for a loaner", async () => {
    const wrapper = await mount({ vehicle: vehicle({ loaner: true }) });

    expect(wrapper.find('[data-test="vehicle-overview-plaque"]').exists()).toBe(
      false,
    );
  });
});
