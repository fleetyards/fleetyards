import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import {
  type Vehicle,
  BoughtViaEnum,
  FeatureFlagName,
  ModelProductionStatusEnum,
  VehicleLoadoutKindEnum,
} from "@/services/fyApi";

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
    modelPaintIds: [],
    model: {
      id: "model-1",
      name: "Odyssey",
      slug: "odyssey",
      inGame: true,
      productionStatus: ModelProductionStatusEnum.FLIGHT_READY,
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
  hideEdit?: boolean;
  hideShipPage?: boolean;
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

const menuStructure = () =>
  Array.from(
    document.body.querySelectorAll('[data-test="dropdown-list"] > *'),
  ).map((item) =>
    item.tagName === "HR" ? "separator" : item.getAttribute("data-test"),
  );

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

  it("orders a hangar card's menu as database, edits, management, organization, removal", async () => {
    await mount();

    expect(items()).toEqual([
      "vehicle-ship-page",
      "vehicle-edit",
      "vehicle-manage-loadouts",
      "vehicle-manage-cargo",
      "vehicle-log",
      "vehicle-toggle-hidden",
      "vehicle-add-to-wishlist",
      "vehicle-remove",
    ]);
    expect(menuStructure()).toEqual([
      "vehicle-ship-page",
      "separator",
      "vehicle-edit",
      "separator",
      "vehicle-manage-loadouts",
      "vehicle-manage-cargo",
      "vehicle-log",
      "separator",
      "vehicle-toggle-hidden",
      "vehicle-add-to-wishlist",
      "separator",
      "vehicle-remove",
    ]);
  });

  it("offers editing without hangar organization on the vehicle page", async () => {
    await mount({ onVehiclePage: true });

    expect(items()).toEqual([
      "vehicle-ship-page",
      "vehicle-edit",
      "vehicle-remove",
    ]);
  });

  it("separates overview editing from removal when the database link is hidden", async () => {
    await mount({ onVehiclePage: true, hideShipPage: true });

    expect(menuStructure()).toEqual([
      "vehicle-edit",
      "separator",
      "vehicle-remove",
    ]);
  });

  it("does not add a separator to a visitor's database-only menu", async () => {
    await mount({ editable: false });

    expect(menuStructure()).toEqual(["vehicle-ship-page"]);
  });

  it("does not leave separators when all groups are hidden", async () => {
    await mount({ editable: false, hideShipPage: true });

    expect(menuStructure()).toEqual([]);
  });

  it("keeps loadout editing with edits and separates it from management", async () => {
    enabledFlags.value = [
      ...enabledFlags.value,
      FeatureFlagName.LOADOUT_EDITOR,
    ];
    await mount({
      hideEdit: true,
      vehicle: vehicle({ model: { ...vehicle().model, hasModules: true } }),
    });

    expect(menuStructure().slice(0, 5)).toEqual([
      "vehicle-ship-page",
      "separator",
      "vehicle-loadout",
      "separator",
      "vehicle-manage-loadouts",
    ]);
  });

  it("offers no loadout editing until the editor is switched on", async () => {
    await mount({
      vehicle: vehicle({ model: { ...vehicle().model, hasModules: true } }),
    });

    expect(items()).not.toContain("vehicle-loadout");
  });

  it("offers no loadout editing on a ship that is not flight ready", async () => {
    enabledFlags.value = [
      ...enabledFlags.value,
      FeatureFlagName.LOADOUT_EDITOR,
    ];
    await mount({
      vehicle: vehicle({
        model: {
          ...vehicle().model,
          hasModules: true,
          productionStatus: ModelProductionStatusEnum.IN_PRODUCTION,
        },
      }),
    });

    expect(items()).not.toContain("vehicle-loadout");
  });

  it("shows a loaner's or wishlist ship's loadout rather than editing it", async () => {
    enabledFlags.value = [
      ...enabledFlags.value,
      FeatureFlagName.LOADOUT_EDITOR,
    ];
    const modular = { model: { ...vehicle().model, hasModules: true } };

    await mount({ vehicle: vehicle({ ...modular, loaner: true }) });

    expect(items()).not.toContain("vehicle-loadout");

    mounted.forEach((wrapper) => wrapper.unmount());
    mounted = [];

    await mount({
      vehicle: vehicle({
        ...modular,
        wanted: true,
        activeLoadout: {
          id: "loadout-1",
          kind: VehicleLoadoutKindEnum.FLEETYARDS,
        },
      } as Partial<Vehicle>),
    });

    expect(items()).toContain("vehicle-loadout");
  });

  it("leaves the ship database to a page that links it", async () => {
    await mount({ onVehiclePage: true, hideShipPage: true });

    expect(items()).not.toContain("vehicle-ship-page");
  });

  it("offers no log without the overview", async () => {
    enabledFlags.value = [FeatureFlagName.SHIP_INVENTORIES];
    await mount();

    expect(items()).not.toContain("vehicle-log");
    expect(items()).toContain("vehicle-manage-loadouts");
  });

  it("offers no cargo without inventories", async () => {
    enabledFlags.value = [FeatureFlagName.VEHICLE_OVERVIEW];
    await mount();

    expect(items()).not.toContain("vehicle-manage-cargo");
  });

  it("moves a wishlist ship to the hangar and keeps its log and cargo out", async () => {
    await mount({ wishlist: true });

    expect(items()).toContain("vehicle-add-to-hangar");
    expect(items()).not.toContain("vehicle-add-to-wishlist");
    expect(items()).not.toContain("vehicle-log");
    expect(items()).not.toContain("vehicle-manage-cargo");
  });

  it("offers to hide a ship, and to show a hidden one again", async () => {
    await mount();

    const toggle = () =>
      document.body.querySelector('[data-test="vehicle-toggle-hidden"]');

    expect(toggle()?.textContent).toContain("Hide from Hangar");

    mounted.forEach((wrapper) => wrapper.unmount());
    mounted = [];

    await mount({ vehicle: vehicle({ hiddenByUser: true }) });

    expect(toggle()?.textContent).toContain("Show in Hangar");
  });

  it("leaves hiding out for the wishlist and a bundled snub craft", async () => {
    await mount({ wishlist: true });

    expect(items()).not.toContain("vehicle-toggle-hidden");

    mounted.forEach((wrapper) => wrapper.unmount());
    mounted = [];

    await mount({ vehicle: vehicle({ bundled: true }) });

    expect(items()).not.toContain("vehicle-toggle-hidden");
  });

  it("offers a visitor add-ons only when some are fitted", async () => {
    const modular = { hasModules: true, hasUpgrades: false };

    await mount({
      editable: false,
      vehicle: vehicle({
        model: { ...vehicle().model, ...modular },
      } as Partial<Vehicle>),
    });

    expect(items()).not.toContain("vehicle-loadout");
  });
});
