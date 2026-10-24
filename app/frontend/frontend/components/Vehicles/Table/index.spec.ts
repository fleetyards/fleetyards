import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import {
  type HangarGroup,
  type Vehicle,
  BoughtViaEnum,
} from "@/services/fyApi";

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

const group = (id: string) =>
  ({
    id,
    name: `Group ${id}`,
    slug: `group-${id}`,
    color: "#ff0000",
  }) as HangarGroup;

const mount = async (
  record: Vehicle,
  editable = true,
  props: Record<string, unknown> = {},
) => {
  await router.push({ name: "hangar" });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    initialState: { session: { currentUser: { username: "me" } } },
    props: { vehicles: [record], editable, ...props },
    plugins: [router],
  });
};

const rowClasses = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.get("tr#vehicle-1").classes();

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

  it("lists the guns a ship carries in the weapons column", async () => {
    await router.push({ name: "hangar" });
    await router.isReady();
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      initialState: {
        session: { currentUser: { username: "me" } },
        hangar: { tableViewCols: ["maxWeaponSize"] },
      },
      props: {
        vehicles: [
          vehicle({
            maxWeaponSize: 3,
            weaponSizes: [
              { size: 2, count: 4 },
              { size: 3, count: 2 },
            ],
          }),
        ],
        editable: true,
      },
      plugins: [router],
    });

    expect(wrapper.get("thead").text()).toContain("Weapons");
    expect(wrapper.get("tr#vehicle-1").text()).toContain("2×S3 · 4×S2");
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

  it("marks the flagship beside its name and tones its row", async () => {
    const wrapper = await mount(vehicle({ flagship: true }));

    expect(wrapper.find('[data-test="vehicle-table-flagship"]').exists()).toBe(
      true,
    );
    expect(rowClasses(wrapper)).toContain("vehicles-table-row--flagship");
  });

  it("tones the rows in the hovered group over the flagship", async () => {
    const wrapper = await mount(
      vehicle({ flagship: true, hangarGroupIds: ["group-1"] }),
      true,
      { highlightedGroupId: "group-1" },
    );

    expect(rowClasses(wrapper)).toContain("vehicles-table-row--highlight");
    expect(rowClasses(wrapper)).not.toContain("vehicles-table-row--flagship");
  });

  it("leaves rows outside the hovered group untoned", async () => {
    const wrapper = await mount(vehicle(), true, {
      highlightedGroupId: "group-1",
    });

    expect(rowClasses(wrapper)).not.toContain("vehicles-table-row--highlight");
  });

  it("shows a private ship's visibility rather than an empty cell", async () => {
    const wrapper = await mount(vehicle({ public: false }));

    expect(
      wrapper.find('[data-test="vehicle-state-visibility"] .fa-lock').exists(),
    ).toBe(true);
  });

  it("folds the groups past the fourth into a count", async () => {
    const wrapper = await mount(
      vehicle({ hangarGroups: ["1", "2", "3", "4", "5", "6"].map(group) }),
    );

    expect(wrapper.findAll('[data-test="hangar-group"]')).toHaveLength(3);
    expect(wrapper.get('[data-test="hangar-group-overflow"]').text()).toBe(
      "+3",
    );
  });

  it("shows four groups without a count", async () => {
    const wrapper = await mount(
      vehicle({ hangarGroups: ["1", "2", "3", "4"].map(group) }),
    );

    expect(wrapper.findAll('[data-test="hangar-group"]')).toHaveLength(4);
    expect(wrapper.find('[data-test="hangar-group-overflow"]').exists()).toBe(
      false,
    );
  });

  it("shows no lock on the wishlist, which is public regardless", async () => {
    const wrapper = await mount(vehicle({ public: false }), true, {
      wishlist: true,
    });

    expect(
      wrapper.find('[data-test="vehicle-state-visibility"] i').exists(),
    ).toBe(false);
  });

  it("unfolds the hidden groups when their count is clicked", async () => {
    const wrapper = await mount(
      vehicle({ hangarGroups: ["1", "2", "3", "4", "5", "6"].map(group) }),
    );

    await wrapper.get('[data-test="hangar-group-overflow"]').trigger("click");

    expect(wrapper.findAll('[data-test="hangar-group"]')).toHaveLength(6);
    expect(wrapper.find('[data-test="hangar-group-overflow"]').exists()).toBe(
      false,
    );
  });
});
