import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import type { Vehicle, VehiclePaint } from "@/services/fyApi";

const paints = ref<VehiclePaint[]>([]);
const updateVehicle = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useVehiclePaints: () => ({ data: paints, isLoading: ref(false) }),
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({
      mutateAsync: updateVehicle,
      isPending: ref(false),
    }),
  }),
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

const mount = () =>
  mountWithDefaults(Component, { props: { vehicle }, plugins: [router] });

const names = (wrapper: Awaited<ReturnType<typeof mountWithDefaults>>) =>
  wrapper
    .findAll('[data-test="vehicle-overview-paint"]')
    .map((button) => button.text());

describe("VehicleOverviewPaintsCard", () => {
  beforeEach(() => {
    updateVehicle.mockReset().mockResolvedValue({});
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

  it("applies a paint that is not on the ship yet", async () => {
    paints.value = [entry("Rust Society", { owned: true })];

    const wrapper = await mount();

    await wrapper.find('[data-test="vehicle-overview-paint"]').trigger("click");
    await flushPromises();

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { modelPaintId: "Rust Society" },
    });
  });

  it("leaves the applied paint alone", async () => {
    paints.value = [entry("Rust Society", { owned: true, applied: true })];

    const wrapper = await mount();

    await wrapper.find('[data-test="vehicle-overview-paint"]').trigger("click");
    await flushPromises();

    expect(updateVehicle).not.toHaveBeenCalled();
  });
});
