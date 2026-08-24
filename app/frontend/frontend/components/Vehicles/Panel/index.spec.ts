import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import { type Vehicle, BoughtViaEnum } from "@/services/fyApi";

// The card carries a store image, and jsdom has no IntersectionObserver for
// useLazyBackground to hand it to.
beforeEach(() => {
  vi.stubGlobal(
    "IntersectionObserver",
    class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  );
});

const NOW = "2026-08-24T12:00:00Z";

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    boughtVia: BoughtViaEnum.PLEDGE_STORE,
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
    model: {
      id: "model-1",
      name: "Odyssey",
      slug: "odyssey",
      media: {},
      inGame: true,
      crew: { min: 1, max: 6 },
      speeds: { scmSpeed: 210, maxSpeed: 1125, groundMaxSpeed: 90 },
      metrics: {
        isGroundVehicle: false,
        length: 110,
        beam: 60,
        height: 22,
        mass: null,
        cargo: 64,
      },
      manufacturer: {
        id: "manufacturer-1",
        name: "RSI",
        slug: "rsi",
      },
    },
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  }) as Vehicle;

// The title links to `ship`, and the manufacturer link is query-only - it
// resolves against the current route, so the router has to be on one.
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: "/",
      name: "hangar",
      component: { template: "<div />" },
    },
    {
      path: "/ships/:slug",
      name: "ship",
      component: { template: "<div />" },
    },
  ],
});

const mount = async (props: { vehicle: Vehicle; highlight?: boolean }) => {
  await router.push({ name: "hangar" });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props,
    plugins: [router],
  });
};

describe("VehiclesPanel", () => {
  it("leaves an ordinary ship untoned", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    expect(wrapper.find(".panel--highlight").exists()).toBe(false);
    expect(wrapper.find(".panel--primary").exists()).toBe(false);
  });

  it("marks the flagship in gold, matching its certificate icon", async () => {
    const wrapper = await mount({ vehicle: vehicle({ flagship: true }) });

    expect(wrapper.find(".panel--highlight").exists()).toBe(true);
    expect(wrapper.find(".vehicle-panel-flagship-icon").exists()).toBe(true);
  });

  it("gives a highlighted group its own tone, not the flagship's", async () => {
    const wrapper = await mount({ vehicle: vehicle(), highlight: true });

    expect(wrapper.find(".panel--primary").exists()).toBe(true);
    expect(wrapper.find(".panel--highlight").exists()).toBe(false);
  });

  // Otherwise the flagship is the one ship in the hovered group whose membership
  // cannot be read - the reason the two states stopped sharing gold.
  it("shows a highlighted flagship as part of the group", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ flagship: true }),
      highlight: true,
    });

    expect(wrapper.find(".panel--primary").exists()).toBe(true);
    expect(wrapper.find(".panel--highlight").exists()).toBe(false);
    expect(wrapper.find(".vehicle-panel-flagship-icon").exists()).toBe(true);
  });
});
