import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import {
  type Vehicle,
  type VehicleLoadout,
  VehicleLoadoutKindEnum,
} from "@/services/fyApi";

const NOW = "2026-10-16T12:00:00Z";

const loadouts = ref<VehicleLoadout[]>([]);
const mutate = vi.fn();
const isPending = ref(false);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useVehicleLoadouts: () => ({ data: loadouts, isLoading: ref(false) }),
  useActivateVehicleLoadout: () => ({ mutate, isPending }),
}));

const openLoadoutView = vi.fn();

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openLoadoutView }),
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({ invalidateVehiclePage: vi.fn() }),
}));

vi.mock("@/frontend/composables/useVehicleRoute", () => ({
  useVehicleRoute: () => () => "/",
}));

const loadout = (overrides: Partial<VehicleLoadout> = {}): VehicleLoadout => ({
  id: "cargo",
  name: "Cargo",
  active: false,
  public: false,
  kind: VehicleLoadoutKindEnum.FLEETYARDS,
  items: [],
  powerPresets: [],
  createdAt: NOW,
  updatedAt: NOW,
  ...overrides,
});

const vehicle = {
  id: "vehicle-1",
  model: { slug: "cutlass-black" },
} as Vehicle;

const router = createRouter({
  history: createWebHashHistory(),
  routes: [{ path: "/", name: "home", component: { template: "<div />" } }],
});

const mount = () =>
  mountWithDefaults(Component, { props: { vehicle }, plugins: [router] });

const row = (id: string) => `[data-test="vehicle-overview-loadout-${id}"]`;

describe("VehicleOverviewLoadoutsCard", () => {
  beforeEach(() => {
    mutate.mockClear();
    openLoadoutView.mockClear();
    isPending.value = false;
    loadouts.value = [
      loadout({ active: true }),
      loadout({ id: "combat", name: "Combat" }),
    ];
  });

  it("lists every loadout and marks the active one", async () => {
    const wrapper = await mount();

    expect(wrapper.find(row("cargo")).classes()).toContain(
      "addon-option--selected",
    );
    expect(wrapper.find(row("combat")).classes()).not.toContain(
      "addon-option--selected",
    );
  });

  it("switches to a loadout picked from the list", async () => {
    const wrapper = await mount();

    await wrapper
      .find(`${row("combat")} .addon-option__toggle`)
      .trigger("click");

    expect(mutate).toHaveBeenCalledWith({
      vehicleId: "vehicle-1",
      id: "combat",
    });
  });

  it("leaves the active loadout and a pending switch alone", async () => {
    const wrapper = await mount();

    await wrapper
      .find(`${row("cargo")} .addon-option__toggle`)
      .trigger("click");

    isPending.value = true;
    await wrapper
      .find(`${row("combat")} .addon-option__toggle`)
      .trigger("click");

    expect(mutate).not.toHaveBeenCalled();
  });

  it("opens a fleetyards loadout here and a linked one on its site", async () => {
    loadouts.value = [
      loadout(),
      loadout({
        id: "erkul",
        name: "Erkul build",
        kind: VehicleLoadoutKindEnum.LINK,
        url: "https://www.erkul.games/loadout/abc",
        urlSource: "erkul",
      }),
    ];

    const wrapper = await mount();

    await wrapper
      .find('[data-test="vehicle-overview-loadout-cargo-view"]')
      .trigger("click");

    expect(openLoadoutView).toHaveBeenCalledWith(vehicle, {
      editable: true,
      loadout: loadouts.value[0],
    });
    expect(
      wrapper
        .find('[data-test="vehicle-overview-loadout-erkul-view"]')
        .attributes("href"),
    ).toBe("https://www.erkul.games/loadout/abc");
  });
});
