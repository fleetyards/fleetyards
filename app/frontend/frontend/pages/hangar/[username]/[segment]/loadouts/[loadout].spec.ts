import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./[loadout].vue";

const { enabled, query, vehicle, loadout, pending, hullHardpoints } =
  vi.hoisted(() => {
    const enabled: Record<string, boolean> = {};
    // Queries still loading, by name, read when the page sets them up.
    const pending: Record<string, boolean> = {};

    const query = (name: string, data: unknown | (() => unknown)) =>
      vi.fn((...args: unknown[]) => {
        const options = args.at(-1) as
          { query?: { enabled?: unknown } } | undefined;
        const flag = options?.query?.enabled;
        enabled[name] =
          typeof flag === "function" ? Boolean(flag()) : Boolean(toValue(flag));

        return {
          data: ref(typeof data === "function" ? data() : data),
          isPending: ref(false),
          isLoading: ref(!!pending[name]),
          isFetching: ref(false),
          isRefetching: ref(false),
          isError: ref(false),
          fetchStatus: ref("idle"),
          error: ref(null),
        };
      });

    const vehicle = {
      id: "vehicle-1",
      name: "Rust Bucket",
      serial: "IC-021",
      model: { slug: "scorpius", name: "Scorpius" },
    };

    const loadout = {
      id: "l1",
      name: "Brawler",
      kind: "fleetyards",
      items: [],
    };

    const hullHardpoints = {
      value: [{ id: "hp-1", name: "hardpoint_power_plant" }] as unknown[],
    };

    return { enabled, query, vehicle, loadout, pending, hullHardpoints };
  });

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useShowVehicle: query("ownVehicle", vehicle),
  useVehicleLoadout: query("ownLoadouts", loadout),
  useVehicleLoadoutSlots: query("ownSlots", []),
  usePublicHangarVehicle: query("publicVehicle", vehicle),
  usePublicVehicleLoadout: query("publicLoadout", loadout),
  usePublicVehicleLoadoutSlots: query("publicSlots", []),
  useModel: query("model", { slug: "scorpius", metrics: {}, speeds: {} }),
  useModelLoadoutSlots: query("hullSlots", []),
  useModelHardpoints: query("modelHardpoints", () => hullHardpoints.value),
  useModelModules: query("modules", { items: [] }),
}));

vi.mock("@/frontend/components/Models/Hardpoints/index.vue", () => ({
  default: {
    name: "Hardpoints",
    props: ["model", "fitting"],
    template: "<div data-test='hardpoints' />",
  },
}));

const openLoadoutModal = vi.fn();

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openLoadoutModal }),
}));

vi.mock("@/frontend/composables/useLoadoutEditor", () => ({
  useLoadoutEditor: () => ({ loadoutEditorAvailable: () => true }),
}));

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "hangar", component: { template: "<div />" } },
    {
      path: "/hangar/:username/",
      name: "hangar-public",
      component: { template: "<div />" },
    },
    {
      path: "/hangar/:username/:segment/loadouts/",
      name: "hangar-vehicle-loadouts",
      component: { template: "<div />" },
    },
    {
      path: "/hangar/:username/:segment/loadouts/:loadout/",
      name: "hangar-vehicle-loadout",
      component: Component,
    },
  ],
});

beforeAll(() => {
  const target = document.createElement("div");
  target.id = "header-right";
  document.body.appendChild(target);
});

afterEach(() => {
  document.getElementById("header-right")!.innerHTML = "";
});

const mount = async (currentUser?: { username: string }) => {
  await router.push("/hangar/owner/ic-021-rust-bucket/loadouts/l1/");
  await router.isReady();

  return mountWithDefaults(Component, {
    plugins: [router],
    initialState: { session: { currentUser } },
  });
};

describe("HangarVehicleLoadoutPage", () => {
  it("shows a visitor the loadout from the public hangar, read-only", async () => {
    const wrapper = await mount({ username: "someone-else" });

    expect(enabled.publicLoadout).toBe(true);
    expect(enabled.ownLoadouts).toBe(false);
    expect(wrapper.text()).toContain("Brawler");
    expect(
      document.querySelector("[data-test='vehicle-loadout-page-edit']"),
    ).toBeNull();

    wrapper.unmount();
  });

  it("hands the hardpoints section the loadout fitted to the ship", async () => {
    const wrapper = await mount();

    const hardpoints = wrapper.findComponent({ name: "Hardpoints" });
    expect(hardpoints.props("fitting")).toEqual([
      expect.objectContaining({ name: "hardpoint_power_plant" }),
    ]);

    wrapper.unmount();
  });

  it("holds the hardpoints back until the loadout's slots are in", async () => {
    pending.publicSlots = true;

    const wrapper = await mount();

    expect(wrapper.findComponent({ name: "Hardpoints" }).exists()).toBe(false);
    expect(
      wrapper.find("[data-test='vehicle-loadout-page-empty']").exists(),
    ).toBe(false);

    pending.publicSlots = false;
    wrapper.unmount();
  });

  it("says when the ship has no hardpoints to fit", async () => {
    hullHardpoints.value = [];

    const wrapper = await mount();

    expect(
      wrapper.find("[data-test='vehicle-loadout-page-empty']").exists(),
    ).toBe(true);

    hullHardpoints.value = [{ id: "hp-1", name: "hardpoint_power_plant" }];
    wrapper.unmount();
  });

  it("sends the owner back to the list for a linked loadout", async () => {
    loadout.kind = "link";

    const wrapper = await mount({ username: "Owner" });
    await flushPromises();

    expect(router.currentRoute.value.name).toBe("hangar-vehicle-loadouts");

    loadout.kind = "fleetyards";
    wrapper.unmount();
  });

  it("lets the owner into the editor on this loadout", async () => {
    const wrapper = await mount({ username: "Owner" });

    expect(enabled.ownLoadouts).toBe(true);
    expect(enabled.publicLoadout).toBe(false);

    (
      document.querySelector(
        "[data-test='vehicle-loadout-page-edit']",
      ) as HTMLElement
    ).click();

    expect(openLoadoutModal).toHaveBeenCalledWith(
      vehicle,
      expect.objectContaining({ editable: true, loadoutId: "l1" }),
    );

    wrapper.unmount();
  });
});
