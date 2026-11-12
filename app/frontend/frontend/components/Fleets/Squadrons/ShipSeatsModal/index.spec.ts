import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import { type MissionSlot, MissionSlottableTypeEnum } from "@/services/fyApi";

const api = vi.hoisted(() => ({
  updateFleetSquadronFlightSlot: vi.fn(),
  slots: [] as unknown[],
}));

vi.mock("@/services/fyApi", async (importOriginal) => {
  const { ref } = await import("vue");

  return {
    ...(await importOriginal<typeof import("@/services/fyApi")>()),
    updateFleetSquadronFlightSlot: api.updateFleetSquadronFlightSlot,
    useFleetSquadronFlight: () => ({
      data: ref({ ships: [{ id: "ship-1", slots: api.slots }] }),
    }),
  };
});

const seat = (overrides: Partial<MissionSlot> = {}): MissionSlot => ({
  id: "gunner",
  slottableType: MissionSlottableTypeEnum.MISSION_SHIP,
  slottableId: "ship-1",
  title: "Gunner",
  position: 0,
  derived: false,
  lead: false,
  candidates: [],
  ...overrides,
});

const mount = (editable = true) =>
  mountWithDefaults<typeof Component>(Component, {
    props: {
      scope: {
        fleetSlug: "fleet",
        squadronSlug: "alpha",
        flightId: "flight-1",
        teamId: "team-1",
      },
      shipId: "ship-1",
      shipTitle: "Hammerhead",
      editable,
    },
  });

describe("FleetSquadronShipSeatsModal", () => {
  beforeEach(() => {
    api.slots = [seat()];
    api.updateFleetSquadronFlightSlot.mockReset().mockResolvedValue({});
  });

  it("renames a seat", async () => {
    const wrapper = await mount();

    await wrapper.find('[data-test="ship-seat-title-gunner"]').trigger("click");
    const input = wrapper.find('[data-test="ship-seat-edit-gunner"]');
    await input.setValue("Turret");
    await input.trigger("keydown", { key: "Enter" });
    await flushPromises();

    expect(api.updateFleetSquadronFlightSlot).toHaveBeenCalledOnce();
    expect(api.updateFleetSquadronFlightSlot).toHaveBeenCalledWith(
      "fleet",
      "alpha",
      "flight-1",
      "gunner",
      { title: "Turret" },
    );
  });

  it("offers no rename to a reader who cannot edit", async () => {
    const wrapper = await mount(false);

    expect(wrapper.find('[data-test="ship-seat-title-gunner"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="ship-seat-gunner"]').text()).toContain(
      "Gunner",
    );
  });
});
