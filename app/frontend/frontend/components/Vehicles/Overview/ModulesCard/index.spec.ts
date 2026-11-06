import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { Vehicle } from "@/services/fyApi";

const isError = ref(false);
const openEditModal = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useModelModules: () => ({
    data: ref({
      items: [
        { id: "cargo", slug: "cargo", name: "Cargo Module" },
        { id: "living", slug: "living", name: "Living Module" },
      ],
    }),
    isLoading: ref(false),
    isError,
  }),
}));

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openEditModal }),
}));

const vehicle = (overrides: Partial<Vehicle> = {}) =>
  ({
    id: "vehicle-1",
    modelModuleIds: ["cargo", "cargo"],
    loaner: false,
    wanted: false,
    model: { name: "Retaliator", slug: "retaliator", hasModules: true },
    ...overrides,
  }) as Vehicle;

const mount = (overrides: Partial<Vehicle> = {}) =>
  mountWithDefaults(Component, { props: { vehicle: vehicle(overrides) } });

const card = '[data-test="vehicle-overview-modules"]';
const editButton = '[data-test="vehicle-overview-modules-edit"]';

describe("VehicleOverviewModulesCard", () => {
  beforeEach(() => {
    isError.value = false;
    openEditModal.mockReset();
  });

  it("lists the modules the ship owns, with how many of each", async () => {
    const wrapper = await mount();

    const rows = wrapper.findAll('[data-test="vehicle-addon"]');

    expect(rows).toHaveLength(1);
    expect(rows[0].text()).toContain("Cargo Module");
    expect(rows[0].text()).toContain("2");
    expect(wrapper.text()).not.toContain("Living Module");
  });

  it("invites the owner to record modules while the ship has none", async () => {
    const wrapper = await mount({ modelModuleIds: [] });

    expect(wrapper.text()).toContain("No modules fitted");
    expect(wrapper.find(editButton).exists()).toBe(true);
  });

  it("opens the vehicle's modules tab", async () => {
    const wrapper = await mount();

    await wrapper.find(editButton).trigger("click");
    await flushPromises();

    expect(openEditModal).toHaveBeenCalledWith(
      expect.objectContaining({ id: "vehicle-1" }),
      { tab: "modules" },
    );
  });

  it("stays away from a ship whose model takes no modules", async () => {
    const base = vehicle();
    const wrapper = await mount({
      model: { ...base.model, hasModules: false },
    });

    expect(wrapper.find(card).exists()).toBe(false);
  });

  it("shows a wishlist ship's modules without offering to edit them", async () => {
    const wrapper = await mount({ wanted: true });

    expect(wrapper.text()).toContain("Cargo Module");
    expect(wrapper.find(editButton).exists()).toBe(false);
  });

  it("leaves a wishlist ship without modules alone", async () => {
    const wrapper = await mount({ wanted: true, modelModuleIds: [] });

    expect(wrapper.find(card).exists()).toBe(false);
  });

  it("does not claim the ship has no modules when the request failed", async () => {
    isError.value = true;

    const wrapper = await mount();

    expect(wrapper.find(card).exists()).toBe(false);
  });
});
