import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import { type Vehicle, BoughtViaEnum, FeatureFlagName } from "@/services/fyApi";

const enabledFlags = ref<FeatureFlagName[]>([]);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (flag: FeatureFlagName) =>
      enabledFlags.value.includes(flag),
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
    modelModuleIds: [],
    modelUpgradeIds: [],
    model: {
      id: "model-1",
      name: "Odyssey",
      slug: "odyssey",
      inGame: true,
      hasModules: false,
      hasUpgrades: false,
    },
    ...overrides,
  }) as unknown as Vehicle;

const stub = { template: "<div />" };

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "hangar", component: stub },
    { path: "/ships/:slug", name: "ship", component: stub },
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

type MountProps = {
  vehicle?: Vehicle;
  editable?: boolean;
  wishlist?: boolean;
  onVehiclePage?: boolean;
  hideGroups?: boolean;
};

let mounted: { unmount: () => void }[] = [];

const mount = async (props: MountProps = {}) => {
  await router.push({ name: "hangar" });
  await router.isReady();

  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    initialState: { session: { currentUser: { username: "me" } } },
    props: { vehicle: vehicle(), editable: true, ...props },
    plugins: [router],
    attachTo: document.body,
  });

  mounted.push(wrapper);

  return wrapper;
};

// The menu teleports to the body.
const items = () =>
  Array.from(
    document.body.querySelectorAll('[data-test="dropdown-list"] [data-test]'),
  ).map((item) => item.getAttribute("data-test"));

describe("VehicleContextMenu", () => {
  beforeEach(() => {
    enabledFlags.value = [
      FeatureFlagName.VEHICLE_OVERVIEW,
      FeatureFlagName.SHIP_INVENTORIES,
    ];
  });

  afterEach(() => {
    mounted.forEach((wrapper) => wrapper.unmount());
    mounted = [];
  });

  it("orders a hangar card's menu as pages, edits, status, removal", async () => {
    await mount();

    expect(items()).toEqual([
      "vehicle-log",
      "vehicle-manage-loadouts",
      "vehicle-manage-cargo",
      "vehicle-ship-page",
      "vehicle-edit",
      "vehicle-edit-name",
      "vehicle-change-picture",
      "vehicle-edit-groups",
      "vehicle-add-to-wishlist",
      "vehicle-remove",
    ]);
  });

  it("leaves out what the vehicle page already offers", async () => {
    await mount({ onVehiclePage: true });

    expect(items()).toEqual([
      "vehicle-ship-page",
      "vehicle-edit-name",
      "vehicle-edit-groups",
      "vehicle-add-to-wishlist",
      "vehicle-remove",
    ]);
  });

  it("leaves the groups to a page that edits them", async () => {
    await mount({ onVehiclePage: true, hideGroups: true });

    expect(items()).not.toContain("vehicle-edit-groups");
  });

  it("offers no log or picture without the overview", async () => {
    enabledFlags.value = [FeatureFlagName.SHIP_INVENTORIES];
    await mount();

    expect(items()).not.toContain("vehicle-log");
    expect(items()).not.toContain("vehicle-change-picture");
    expect(items()).toContain("vehicle-manage-loadouts");
  });

  it("offers no cargo without inventories", async () => {
    enabledFlags.value = [FeatureFlagName.VEHICLE_OVERVIEW];
    await mount();

    expect(items()).not.toContain("vehicle-manage-cargo");
  });

  it("moves a wishlist ship to the hangar and keeps its cargo and groups out", async () => {
    await mount({ wishlist: true });

    expect(items()).toContain("vehicle-add-to-hangar");
    expect(items()).not.toContain("vehicle-add-to-wishlist");
    expect(items()).not.toContain("vehicle-manage-cargo");
    expect(items()).not.toContain("vehicle-edit-groups");
  });

  it("offers a visitor add-ons only when some are fitted", async () => {
    const modular = { hasModules: true, hasUpgrades: false };

    await mount({
      editable: false,
      vehicle: vehicle({
        model: { ...vehicle().model, ...modular },
      } as Partial<Vehicle>),
    });

    expect(items()).not.toContain("vehicle-addons");
  });
});
