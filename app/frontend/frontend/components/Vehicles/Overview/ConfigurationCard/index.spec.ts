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
const vehicle = {
  id: "ship",
  model: { hasPaints: true },
  alternativeNames: ["Alias"],
  boughtViaLabel: "Pledge",
  hangarGroups: [],
  upgrade: { name: "Kit" },
  modulePackage: { name: "Package" },
} as unknown as Vehicle;

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
