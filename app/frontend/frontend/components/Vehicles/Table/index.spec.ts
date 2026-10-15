import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import { type Vehicle, BoughtViaEnum } from "@/services/fyApi";

const vehicleOverviewEnabled = ref(false);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: () => vehicleOverviewEnabled.value,
  }),
}));

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    serial: "OD-0001-YS",
    boughtVia: BoughtViaEnum.PLEDGE_STORE,
    wanted: false,
    loaner: false,
    hangarGroupIds: [],
    hangarGroups: [],
    modelModuleIds: [],
    modelUpgradeIds: [],
    modelPaintIds: [],
    model: {
      id: "model-1",
      name: "Odyssey",
      slug: "odyssey",
      media: {},
      inGame: true,
      manufacturer: { id: "manufacturer-1", name: "RSI", slug: "rsi" },
    },
    ...overrides,
  }) as Vehicle;

const stub = { template: "<div />" };

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "hangar", component: stub },
    { path: "/ships/:slug", name: "ship", component: stub },
    {
      path: "/hangar/:username/:segment/overview",
      name: "hangar-vehicle-overview",
      component: stub,
    },
    {
      path: "/hangar/:username/:segment/log",
      name: "hangar-vehicle-log",
      component: stub,
    },
    {
      path: "/hangar/:username/:segment/loadouts",
      name: "hangar-vehicle-loadouts",
      component: stub,
    },
    {
      path: "/hangar/:username/:segment/cargo",
      name: "hangar-vehicle-cargo",
      component: stub,
    },
  ],
});

const mount = async (record: Vehicle, editable = true) => {
  await router.push({ name: "hangar" });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    initialState: { session: { currentUser: { username: "me" } } },
    props: { vehicles: [record], editable },
    plugins: [router],
  });
};

const nameHref = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.find('[data-test="vehicle-table-name"]').attributes("href");

describe("VehiclesTable", () => {
  beforeEach(() => {
    vehicleOverviewEnabled.value = true;
    // The row images load lazily, and jsdom has no IntersectionObserver.
    vi.stubGlobal(
      "IntersectionObserver",
      class {
        observe() {}
        unobserve() {}
        disconnect() {}
      },
    );
  });

  it("opens the owner's ship on its overview", async () => {
    const wrapper = await mount(vehicle());

    expect(nameHref(wrapper)).toBe("#/hangar/me/od-0001-ys-vehicle-1/overview");
    expect(
      wrapper.get('[data-test="vehicle-table-name"]').attributes("data-tour"),
    ).toBe("vehicle-overview");
  });

  it("opens a loaner on its model", async () => {
    const wrapper = await mount(vehicle({ loaner: true }));

    expect(nameHref(wrapper)).toBe("#/ships/odyssey");
    expect(
      wrapper.get('[data-test="vehicle-table-name"]').attributes("data-tour"),
    ).toBeUndefined();
  });

  it("opens the model without the overview", async () => {
    vehicleOverviewEnabled.value = false;
    const wrapper = await mount(vehicle());

    expect(nameHref(wrapper)).toBe("#/ships/odyssey");
    expect(
      wrapper.get('[data-test="vehicle-table-name"]').attributes("data-tour"),
    ).toBeUndefined();
  });
});
