import { describe, it, expect, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { Vehicle } from "@/services/fyApi";
import Component from "./index.vue";

const { openEditModal, emit } = vi.hoisted(() => ({
  openEditModal: vi.fn(),
  emit: vi.fn(),
}));
vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openEditModal }),
}));
vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));
const paints = ref<{ owned: boolean; pledged: boolean }[] | undefined>();
vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useVehiclePaints: () => ({
    data: paints,
    isLoading: ref(false),
    isPlaceholderData: ref(false),
  }),
}));
const vehicle = {
  id: "ship",
  model: { hasPaints: true },
  alternativeNames: ["Alias"],
  boughtViaLabel: "Pledge",
  hangarGroups: [],
  modelPaintIds: [],
  upgrade: { name: "Kit" },
  modulePackage: { name: "Package" },
} as unknown as Vehicle;

describe("Configuration paints", () => {
  const paintFact = async (overrides: Partial<Vehicle> = {}) => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: { ...vehicle, ...overrides } },
    });
    return wrapper.get('[data-test="vehicle-fact-paint"]').text();
  };

  it("counts a pledged paint with the recorded ones", async () => {
    paints.value = [
      { owned: true, pledged: false },
      { owned: false, pledged: true },
      { owned: false, pledged: false },
    ];

    expect(await paintFact()).toContain("2 paints");
  });

  it("calls a ship with neither by its standard livery", async () => {
    paints.value = [{ owned: false, pledged: false }];

    expect(await paintFact()).toContain("Standard livery");
  });

  it("does not call a ship standard before the list is back", async () => {
    paints.value = undefined;

    expect(await paintFact()).not.toContain("Standard livery");
  });

  it("counts the recorded paints until the list is back", async () => {
    paints.value = undefined;

    expect(await paintFact({ modelPaintIds: ["a", "b"] })).toContain(
      "2 paints",
    );
  });
});

describe("Configuration edits", () => {
  it("opens the editor for each editable value", async () => {
    const wrapper = await mountWithDefaults(Component, { props: { vehicle } });
    for (const [fact, tab] of [
      ["paint", "paint"],
      ["upgrade", "upgrades"],
      ["modulePackage", "modules"],
    ]) {
      await wrapper
        .get(`[data-test="vehicle-fact-${fact}"] button`)
        .trigger("click");
      expect(openEditModal).toHaveBeenLastCalledWith(vehicle, { tab });
    }
    await wrapper
      .get('[data-test="vehicle-fact-boughtVia"] button')
      .trigger("click");
    expect(openEditModal).toHaveBeenLastCalledWith(vehicle);
    await wrapper
      .get('[data-test="vehicle-fact-alternativeNames"] button')
      .trigger("click");
    expect(openEditModal).toHaveBeenLastCalledWith(vehicle, { tab: "names" });
    await wrapper.get('[data-test="vehicle-groups-edit"]').trigger("click");
    expect(openEditModal).toHaveBeenLastCalledWith(vehicle, { tab: "groups" });
    await wrapper.get('[data-test="vehicle-location-edit"]').trigger("click");
    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ props: { vehicle } }),
    );
  });
  it("keeps loaner configuration read-only", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: { ...vehicle, loaner: true } },
    });
    expect(
      wrapper
        .findAll("button")
        .every((button) => button.attributes("disabled") !== undefined),
    ).toBe(true);
    expect(wrapper.findAll(".fa-pen")).toHaveLength(0);
  });
});
