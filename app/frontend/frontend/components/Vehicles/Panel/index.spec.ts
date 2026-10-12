import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
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

const vehicleOverviewEnabled = ref(false);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: () => vehicleOverviewEnabled.value,
  }),
}));

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
    logEntriesPublicByDefault: false,
    model: {
      id: "model-1",
      name: "Odyssey",
      slug: "odyssey",
      media: {},
      inGame: true,
      crew: { value: 6, label: "6" },
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
    // An editable panel carries the ship's menu, which links to every tab.
    {
      path: "/hangar/:username/:segment/overview",
      name: "hangar-vehicle-overview",
      component: { template: "<div />" },
    },
    {
      path: "/hangar/:username/:segment/log",
      name: "hangar-vehicle-log",
      component: { template: "<div />" },
    },
    {
      path: "/hangar/:username/:segment/loadouts",
      name: "hangar-vehicle-loadouts",
      component: { template: "<div />" },
    },
    {
      path: "/hangar/:username/:segment/cargo",
      name: "hangar-vehicle-cargo",
      component: { template: "<div />" },
    },
  ],
});

const mount = async (props: {
  vehicle: Vehicle;
  highlight?: boolean;
  sortable?: boolean;
  publicLogUsername?: string;
  editable?: boolean;
}) => {
  await router.push({ name: "hangar" });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    initialState: { session: { currentUser: { username: "me" } } },
    props,
    plugins: [router],
  });
};

describe("VehiclesPanel", () => {
  beforeEach(() => {
    vehicleOverviewEnabled.value = false;
  });

  const titleHref = (wrapper: Awaited<ReturnType<typeof mount>>) =>
    wrapper.find('[data-test="vehicle-panel-title"]').attributes("href");

  it("opens the owner's ship on its overview once there is one", async () => {
    vehicleOverviewEnabled.value = true;

    const wrapper = await mount({
      vehicle: vehicle({ serial: "IC-0210-AB" }),
      editable: true,
    });

    expect(titleHref(wrapper)).toContain(
      "/hangar/me/ic-0210-ab-vehicle-1/overview",
    );
  });

  it("opens the model while the overview is not rolled out", async () => {
    const wrapper = await mount({ vehicle: vehicle(), editable: true });

    expect(titleHref(wrapper)).toContain("/ships/odyssey");
  });

  it("opens the model for someone else's ship", async () => {
    vehicleOverviewEnabled.value = true;

    const wrapper = await mount({ vehicle: vehicle() });

    expect(titleHref(wrapper)).toContain("/ships/odyssey");
  });

  const withPicture = () =>
    vehicle({
      image: {
        name: "ship.jpg",
        contentType: "image/jpeg",
        size: 1024,
        url: "https://example.test/own.jpg",
        mediumUrl: "https://example.test/own.webp",
      },
      paint: {
        id: "paint-1",
        name: "Ghoulish Green",
        slug: "ghoulish-green",
        media: {
          storeImage: {
            name: "paint",
            mediumUrl: "https://example.test/paint.webp",
          },
        },
      } as Vehicle["paint"],
    });

  it("draws the owner's picture before the paint's render", async () => {
    const wrapper = await mount({ vehicle: withPicture() });

    expect(wrapper.findComponent(ModelPanel).props("storeImage")).toBe(
      "https://example.test/own.webp",
    );
  });

  it("offers the public log only for a ship with shared entries", async () => {
    const shared = await mount({
      vehicle: { ...vehicle(), publicLogEntriesCount: 2 } as Vehicle,
      publicLogUsername: "captain",
    });
    const empty = await mount({
      vehicle: { ...vehicle(), publicLogEntriesCount: 0 } as Vehicle,
      publicLogUsername: "captain",
    });

    expect(shared.find('[data-test="vehicle-public-log"]').exists()).toBe(true);
    expect(empty.find('[data-test="vehicle-public-log"]').exists()).toBe(false);
  });

  it("offers the dedication plaque only on someone else's dedicated ship", async () => {
    const dedicated = await mount({
      vehicle: vehicle({ dedication: "To boldly go", public: true }),
    });
    const undedicated = await mount({ vehicle: vehicle() });
    const own = await mount({
      vehicle: vehicle({ dedication: "To boldly go" }),
      editable: true,
    });

    expect(dedicated.find('[data-test="vehicle-plaque-show"]').exists()).toBe(
      true,
    );
    expect(undedicated.find('[data-test="vehicle-plaque-show"]').exists()).toBe(
      false,
    );
    expect(own.find('[data-test="vehicle-plaque-show"]').exists()).toBe(false);
  });

  it("keeps the plaque of a private ship to itself", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ dedication: "To boldly go", public: false }),
    });

    expect(wrapper.find('[data-test="vehicle-plaque-show"]').exists()).toBe(
      false,
    );
  });

  it("draws a picture picked from the gallery before the paint's render", async () => {
    const wrapper = await mount({
      vehicle: {
        ...withPicture(),
        image: undefined,
        modelImage: {
          name: "gallery.jpg",
          contentType: "image/jpeg",
          size: 1024,
          url: "https://example.test/gallery.jpg",
          mediumUrl: "https://example.test/gallery.webp",
        },
      },
    });

    expect(wrapper.findComponent(ModelPanel).props("storeImage")).toBe(
      "https://example.test/gallery.webp",
    );
  });

  it("draws the paint's render when the owner set no picture", async () => {
    const wrapper = await mount({
      vehicle: { ...withPicture(), image: undefined },
    });

    expect(wrapper.findComponent(ModelPanel).props("storeImage")).toBe(
      "https://example.test/paint.webp",
    );
  });

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

  it("draws no grip unless the grid can be dragged", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    expect(wrapper.find('[data-test="vehicle-panel-grip"]').exists()).toBe(
      false,
    );
  });

  it("draws the grip the grid drags by", async () => {
    const wrapper = await mount({ vehicle: vehicle(), sortable: true });

    expect(
      wrapper.find('[data-test="vehicle-panel-grip"]').classes(),
    ).toContain("vehicle-panel-grip");
  });

  it("moves the ship one place with the arrow keys on its grip", async () => {
    const wrapper = await mount({ vehicle: vehicle(), sortable: true });
    const grip = wrapper.find('[data-test="vehicle-panel-grip"]');

    await grip.trigger("keydown", { key: "ArrowUp" });
    await grip.trigger("keydown", { key: "ArrowRight" });

    expect(wrapper.emitted("move")).toEqual([[-1], [1]]);
  });
});
