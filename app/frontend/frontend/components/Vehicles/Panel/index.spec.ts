import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import {
  type Vehicle,
  BoughtViaEnum,
  VehicleLoadoutKindEnum,
} from "@/services/fyApi";

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

const openLoadoutModal = vi.fn();
const openEditModal = vi.fn();
const openLoadoutView = vi.fn();

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({
    openLoadoutModal,
    openEditModal,
    openLoadoutView,
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
    modelPaintIds: [],
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
    expect(
      wrapper.get('[data-test="vehicle-panel-title"]').attributes("data-tour"),
    ).toBe("vehicle-overview");
  });

  it("opens the model while the overview is not rolled out", async () => {
    const wrapper = await mount({ vehicle: vehicle(), editable: true });

    expect(titleHref(wrapper)).toContain("/ships/odyssey");
    expect(
      wrapper.get('[data-test="vehicle-panel-title"]').attributes("data-tour"),
    ).toBeUndefined();
  });

  it("opens the model for someone else's ship", async () => {
    vehicleOverviewEnabled.value = true;

    const wrapper = await mount({ vehicle: vehicle() });

    expect(titleHref(wrapper)).toContain("/ships/odyssey");
    expect(
      wrapper.get('[data-test="vehicle-panel-title"]').attributes("data-tour"),
    ).toBeUndefined();
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
      paintPicture: {
        name: "paint",
        contentType: "image/jpeg",
        size: 1024,
        url: "https://example.test/paint.jpg",
        mediumUrl: "https://example.test/paint.webp",
      },
    });

  it("draws the uploaded picture before a paint picture", async () => {
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

describe("vehicle add-ons shortcut", () => {
  it.each([
    { hasModules: true, hasUpgrades: false, tab: "modules" },
    { hasModules: false, hasUpgrades: true, tab: "upgrades" },
  ])(
    "opens the owner's $tab on the vehicle",
    async ({ hasModules, hasUpgrades, tab }) => {
      const ship = vehicle({
        model: { ...vehicle().model, hasModules, hasUpgrades },
      });
      const wrapper = await mount({ vehicle: ship, editable: true });

      await wrapper.find(".vehicle-panel-addons").trigger("click");

      expect(openEditModal).toHaveBeenLastCalledWith(ship, { tab });
    },
  );

  it("shows what is fitted on the owner's loaner", async () => {
    const ship = vehicle({
      loaner: true,
      modelModuleIds: ["m1"],
      model: { ...vehicle().model, hasModules: true },
    });
    const wrapper = await mount({ vehicle: ship, editable: true });

    await wrapper.find(".vehicle-panel-addons").trigger("click");

    expect(openEditModal).not.toHaveBeenCalledWith(ship, expect.anything());
    expect(openLoadoutView).toHaveBeenLastCalledWith(ship);
  });

  it("shows a visitor what is fitted", async () => {
    const ship = vehicle({
      modelModuleIds: ["m1"],
      model: { ...vehicle().model, hasModules: true },
    });
    const wrapper = await mount({ vehicle: ship, editable: false });

    await wrapper.find(".vehicle-panel-addons").trigger("click");

    expect(openLoadoutView).toHaveBeenLastCalledWith(ship);
  });
});

describe("loadout marker", () => {
  const fitted = {
    id: "l1",
    name: "Hauler",
    active: true,
    kind: VehicleLoadoutKindEnum.FLEETYARDS,
    items: [],
    createdAt: "2026-10-01T00:00:00Z",
    updatedAt: "2026-10-01T00:00:00Z",
  };

  it("shows the owner the loadout, with a way into the editor", async () => {
    const ship = vehicle({ activeLoadout: fitted });
    const wrapper = await mount({ vehicle: ship, editable: true });

    await wrapper.get("[data-test='loadout-marker']").trigger("click");

    expect(openLoadoutView).toHaveBeenLastCalledWith(ship, { editable: true });
  });

  it("shows a visitor the loadout", async () => {
    const ship = vehicle({ activeLoadout: fitted });
    const wrapper = await mount({ vehicle: ship, editable: false });

    await wrapper.get("[data-test='loadout-marker']").trigger("click");

    expect(openLoadoutView).toHaveBeenLastCalledWith(ship, { editable: false });
  });
});
