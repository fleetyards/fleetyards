import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import { type Vehicle, BoughtViaEnum } from "@/services/fyApi";

const vehicleOverviewEnabled = ref(true);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: () => vehicleOverviewEnabled.value,
  }),
}));

const vehicle = {
  id: "vehicle-1",
  serial: "ODY-1",
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
} as unknown as Vehicle;

const stub = { template: "<div />" };

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "hangar", component: stub },
    { path: "/ships/:slug", name: "ship", component: stub },
    { path: "/hangar/:id/log", name: "hangar-vehicle-log", component: stub },
    {
      path: "/hangar/:id/loadouts",
      name: "hangar-vehicle-loadouts",
      component: stub,
    },
    {
      path: "/hangar/:id/cargo",
      name: "hangar-vehicle-cargo",
      component: stub,
    },
  ],
});

const mount = async (props: { onVehiclePage?: boolean } = {}) => {
  await router.push({ name: "hangar" });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { vehicle, editable: true, ...props },
    plugins: [router],
    attachTo: document.body,
  });
};

// The menu teleports to the body.
const items = () =>
  Array.from(
    document.body.querySelectorAll('[data-test="dropdown-list"] [data-test]'),
  ).map((item) => item.getAttribute("data-test"));

describe("VehicleContextMenu", () => {
  beforeEach(() => {
    vehicleOverviewEnabled.value = true;
  });

  afterEach(() => {
    document.body.innerHTML = "";
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

    expect(items()).not.toContain("vehicle-log");
    expect(items()).not.toContain("vehicle-manage-loadouts");
    expect(items()).not.toContain("vehicle-manage-cargo");
    expect(items()).not.toContain("vehicle-change-picture");
    expect(items()).not.toContain("vehicle-edit-groups");
    expect(items()).toContain("vehicle-ship-page");
  });

  it("offers no log or picture without the overview", async () => {
    vehicleOverviewEnabled.value = false;
    await mount();

    expect(items()).not.toContain("vehicle-log");
    expect(items()).not.toContain("vehicle-change-picture");
  });
});
