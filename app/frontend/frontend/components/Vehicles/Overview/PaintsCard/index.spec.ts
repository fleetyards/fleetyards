import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import type { Vehicle, VehiclePaint } from "@/services/fyApi";

const paints = ref<VehiclePaint[]>([]);
const openLoadoutModal = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useVehiclePaints: () => ({ data: paints, isLoading: ref(false) }),
}));

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openLoadoutModal }),
}));

const entry = (
  name: string,
  overrides: Partial<VehiclePaint> = {},
): VehiclePaint => ({
  owned: false,
  applied: false,
  paint: { id: name, name, slug: name, media: {} } as VehiclePaint["paint"],
  ...overrides,
});

const vehicle = {
  id: "vehicle-1",
  model: { name: "Ironclad", slug: "ironclad" },
} as Vehicle;

// "More for this ship" links to the ship page.
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "hangar", component: { template: "<div />" } },
    { path: "/ships/:slug", name: "ship", component: { template: "<div />" } },
  ],
});

const mount = (props: { vehicle: Vehicle } = { vehicle }) =>
  mountWithDefaults(Component, { props, plugins: [router] });

const names = (wrapper: Awaited<ReturnType<typeof mountWithDefaults>>) =>
  wrapper
    .findAll('[data-test="vehicle-overview-paint"]')
    .map((button) => button.text());

describe("VehicleOverviewPaintsCard", () => {
  beforeEach(() => {
    openLoadoutModal.mockReset();
  });

  it("shows only the paints the owner has pledged for", async () => {
    paints.value = [
      entry("Rust Society", { owned: true }),
      entry("Stormbringer"),
    ];

    const wrapper = await mount();

    expect(names(wrapper)).toEqual(["Rust Society"]);
  });

  it("offers the model's paints when none is owned", async () => {
    paints.value = [entry("Rust Society"), entry("Stormbringer")];

    const wrapper = await mount();

    expect(names(wrapper)).toEqual(["Rust Society", "Stormbringer"]);
  });

  it("opens the loadout paints tab without a preselection from the header", async () => {
    paints.value = [entry("Rust Society", { owned: true })];

    const wrapper = await mount();

    await wrapper
      .find('[data-test="vehicle-overview-paints-all"]')
      .trigger("click");
    await flushPromises();

    expect(openLoadoutModal).toHaveBeenCalledWith(vehicle, {
      tab: "paints",
      editable: true,
      paintId: undefined,
    });
  });

  it("opens the loadout paints tab from a paint", async () => {
    paints.value = [entry("Rust Society", { owned: true })];

    const wrapper = await mount();

    await wrapper.find('[data-test="vehicle-overview-paint"]').trigger("click");
    await flushPromises();

    expect(openLoadoutModal).toHaveBeenCalledWith(vehicle, {
      tab: "paints",
      editable: true,
      paintId: "Rust Society",
    });
  });

  it("opens the same editor from the applied paint", async () => {
    paints.value = [entry("Rust Society", { owned: true, applied: true })];

    const wrapper = await mount();

    await wrapper.find('[data-test="vehicle-overview-paint"]').trigger("click");
    await flushPromises();

    expect(openLoadoutModal).toHaveBeenCalledWith(vehicle, {
      tab: "paints",
      editable: true,
      paintId: "Rust Society",
    });
  });
});
