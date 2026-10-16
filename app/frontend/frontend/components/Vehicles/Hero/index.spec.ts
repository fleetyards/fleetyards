import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { flushPromises } from "@vue/test-utils";
import Component from "./index.vue";
import {
  type Vehicle,
  BoughtViaEnum,
  VehicleLoadoutItemTypeEnum,
  VehicleLoadoutKindEnum,
} from "@/services/fyApi";

// The viewer pulls three.js in, which the test environment cannot load.
vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  __esModule: true,
  default: { name: "HoloViewer", props: ["models"], template: "<div />" },
}));

vi.mock("@/frontend/components/Vehicles/ContextMenu/index.vue", () => ({
  default: {
    name: "VehicleContextMenu",
    props: ["hideShipPage"],
    template: "<div />",
  },
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelModules: () => ({
    data: ref({ items: [{ id: "module-1", metrics: { cargo: 32 } }] }),
  }),
}));

const openEditModal = vi.fn();
const openLoadoutView = vi.fn();
const mutateAsync = vi.fn().mockResolvedValue({});

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync, isPending: ref(false) }),
  }),
}));

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openEditModal, openLoadoutView }),
}));

const vehicle = {
  id: "vehicle-1",
  name: "Rust Bucket",
  serial: "IC-021",
  location: "Lorville",
  boughtVia: BoughtViaEnum.PLEDGE_STORE,
  flagship: true,
  public: true,
  wanted: false,
  loaner: false,
  model: {
    id: "model-1",
    name: "Ironclad",
    slug: "ironclad",
    media: {},
    metrics: { length: 123, cargo: 64 },
    speeds: {},
    manufacturer: { id: "manufacturer-1", name: "Drake", slug: "drake" },
  },
  createdAt: "2026-10-12T12:00:00Z",
} as unknown as Vehicle;

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "hangar", component: { template: "<div />" } },
    { path: "/ships/:slug", name: "ship", component: { template: "<div />" } },
  ],
});

const setViewport = (phone: boolean) => {
  window.matchMedia = ((query: string) => ({
    matches: phone,
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

const originalMatchMedia = window.matchMedia;

afterEach(() => {
  window.matchMedia = originalMatchMedia;
});

const menuOffersShipPage = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  !wrapper.findComponent({ name: "VehicleContextMenu" }).props("hideShipPage");

const mount = (compact: boolean, overrides: Partial<Vehicle> = {}) =>
  mountWithDefaults(Component, {
    props: { vehicle: { ...vehicle, ...overrides }, compact },
    plugins: [router],
  });

describe("VehicleHero", () => {
  describe("the holo", () => {
    const withHolos = {
      model: {
        ...vehicle.model,
        media: {
          holo: { url: "https://example.test/holo.glb" },
          holoLite: { url: "https://example.test/holo_lite.glb" },
        },
      },
    } as Partial<Vehicle>;

    // The testing store stubs its actions, so the 3D view starts open.
    const shownHolo = async () => {
      const wrapper = await mountWithDefaults(Component, {
        props: { vehicle: { ...vehicle, ...withHolos }, compact: false },
        plugins: [router],
        initialState: { vehicleView: { holoVehicleIds: [vehicle.id] } },
      });
      await flushPromises();

      return wrapper.findComponent({ name: "HoloViewer" }).props("models")[0]
        .path;
    };

    it("loads the lite export on a phone", async () => {
      setViewport(true);

      expect(await shownHolo()).toBe("https://example.test/holo_lite.glb");
    });

    it("loads the full holo elsewhere", async () => {
      setViewport(false);

      expect(await shownHolo()).toBe("https://example.test/holo.glb");
    });
  });

  it("names the ship and where it is", async () => {
    const wrapper = await mount(false);

    expect(wrapper.find("h1").text()).toBe("Rust Bucket");
    expect(
      wrapper.find('[data-test="vehicle-hero-location"]').text(),
    ).toContain("Lorville");
  });

  it("switches a wishlist ship's sale notifications from its badge", async () => {
    const wrapper = await mount(false, { wanted: true, saleNotify: false });
    const badge = wrapper.find('[data-test="vehicle-badge-sale-notify"]');

    expect(badge.attributes("aria-pressed")).toBe("false");

    await badge.trigger("click");

    expect(mutateAsync).toHaveBeenLastCalledWith({
      id: "vehicle-1",
      data: { saleNotify: true },
    });
  });

  it("shows the sale notification badge only on a wishlist ship", async () => {
    const wrapper = await mount(false, { saleNotify: true });

    expect(
      wrapper.find('[data-test="vehicle-badge-sale-notify"]').exists(),
    ).toBe(false);
  });

  it("calls only an uploaded picture the owner's own", async () => {
    const picture = {
      url: "https://example.test/picture.jpg",
    } as Vehicle["image"];
    const uploaded = await mount(false, {
      image: picture,
      imageUploaded: true,
    });
    const picked = await mount(false, { image: picture, imageUploaded: false });

    expect(uploaded.find(".vehicle-hero__own-picture").exists()).toBe(true);
    expect(picked.find(".vehicle-hero__own-picture").exists()).toBe(false);
  });

  it("offers no picture for a wishlist ship", async () => {
    const wrapper = await mount(false, { wanted: true });

    expect(wrapper.find('[data-test="vehicle-image-edit"]').exists()).toBe(
      false,
    );
  });

  it("counts the active loadout's modules into the stats", async () => {
    const loadout = (kind: VehicleLoadoutKindEnum) => ({
      id: "loadout-1",
      name: "Hauler",
      active: true,
      kind,
      items: [
        {
          itemType: VehicleLoadoutItemTypeEnum.MODEL_MODULE,
          itemId: "module-1",
          slotPath: "hardpoint_front_module",
        },
      ],
    });
    const cargo = async (overrides: Partial<Vehicle> = {}) =>
      (await mount(false, overrides))
        .findComponent({ name: "VehicleOverviewSpecs" })
        .props("moduleCargo");

    expect(await cargo()).toBe(0);
    expect(
      await cargo({
        activeLoadout: loadout(VehicleLoadoutKindEnum.FLEETYARDS),
      } as Partial<Vehicle>),
    ).toBe(32);
    expect(
      await cargo({
        activeLoadout: loadout(VehicleLoadoutKindEnum.LINK),
      } as Partial<Vehicle>),
    ).toBe(0);
  });

  it("says which loadout the ship flies with and opens it", async () => {
    const bare = await mount(false);
    expect(bare.find('[data-test="vehicle-badge-loadout"]').exists()).toBe(
      false,
    );

    const activeLoadout = {
      id: "loadout-1",
      name: "Hauler",
      active: true,
      kind: VehicleLoadoutKindEnum.FLEETYARDS,
      items: [],
      createdAt: "2026-10-12T12:00:00Z",
      updatedAt: "2026-10-12T12:00:00Z",
    };
    const wrapper = await mount(false, { activeLoadout } as Partial<Vehicle>);
    const badge = wrapper.find('[data-test="vehicle-badge-loadout"]');

    expect(badge.text()).toContain("Hauler");

    await badge.trigger("click");

    expect(openLoadoutView).toHaveBeenLastCalledWith(
      expect.objectContaining({ id: "vehicle-1" }),
      { editable: true },
    );
  });

  it("links a linked loadout's badge to its site", async () => {
    const wrapper = await mount(false, {
      activeLoadout: {
        id: "loadout-2",
        name: "Erkul build",
        active: true,
        kind: VehicleLoadoutKindEnum.LINK,
        url: "https://www.erkul.games/loadout/abc",
        urlSource: "erkul",
        items: [],
        createdAt: "2026-10-12T12:00:00Z",
        updatedAt: "2026-10-12T12:00:00Z",
      },
    } as Partial<Vehicle>);
    const badge = wrapper.find('[data-test="vehicle-badge-loadout"]');

    expect(badge.element.tagName).toBe("A");
    expect(badge.attributes("href")).toBe(
      "https://www.erkul.games/loadout/abc",
    );
  });

  it("shrinks into the banner without leaving the page", async () => {
    const wrapper = await mount(false);

    expect(wrapper.classes()).not.toContain("vehicle-hero--compact");

    await wrapper.setProps({ compact: true });

    expect(wrapper.classes()).toContain("vehicle-hero--compact");
    expect(wrapper.find("h1").text()).toBe("Rust Bucket");
  });

  it("leaves the ship database to its own link on a desktop overview", async () => {
    setViewport(false);

    expect(menuOffersShipPage(await mount(false))).toBe(false);
  });

  it("keeps the ship database in the menu where the links are hidden", async () => {
    setViewport(false);
    expect(menuOffersShipPage(await mount(true))).toBe(true);

    setViewport(true);
    expect(menuOffersShipPage(await mount(false))).toBe(true);
  });
});

it("opens image editing on the image tab of the vehicle editor", async () => {
  const wrapper = await mount(false);
  await wrapper.find('[data-test="vehicle-image-edit"]').trigger("click");

  expect(openEditModal).toHaveBeenLastCalledWith(vehicle, { tab: "image" });
});
