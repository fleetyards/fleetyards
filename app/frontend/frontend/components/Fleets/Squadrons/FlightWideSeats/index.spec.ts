import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import { type MissionSlot, MissionSlottableTypeEnum } from "@/services/fyApi";

const api = vi.hoisted(() => ({
  updateFleetSquadronFlightSlot: vi.fn(),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  updateFleetSquadronFlightSlot: api.updateFleetSquadronFlightSlot,
}));

const seat = (overrides: Partial<MissionSlot> = {}): MissionSlot => ({
  id: "seat-1",
  slottableType: MissionSlottableTypeEnum.MISSION_TEAM,
  slottableId: "team-1",
  title: "Comms",
  position: 0,
  derived: false,
  lead: false,
  candidates: [],
  ...overrides,
});

const mount = (seats: MissionSlot[]) =>
  mountWithDefaults<typeof Component>(Component, {
    props: {
      scope: {
        fleetSlug: "fleet",
        squadronSlug: "alpha",
        flightId: "flight-1",
        teamId: "team-1",
      },
      seats,
      editable: true,
    },
  });

describe("FleetSquadronFlightWideSeats", () => {
  it("keeps the lead seat in place and offers to remove the others", async () => {
    const wrapper = await mount([
      seat({ id: "lead", title: "Flight lead", lead: true }),
      seat({ id: "comms" }),
    ]);

    const lead = wrapper.find('[data-test="flight-wide-seat-lead"]');
    const comms = wrapper.find('[data-test="flight-wide-seat-comms"]');

    expect(lead.attributes("data-lead")).toBeDefined();
    expect(lead.find(".wide-seats__grip").exists()).toBe(false);
    expect(lead.findAll("button.btn")).toHaveLength(0);
    expect(comms.find(".wide-seats__grip").exists()).toBe(true);
    expect(comms.findAll("button.btn")).toHaveLength(1);
  });

  describe("renaming", () => {
    beforeEach(() => {
      api.updateFleetSquadronFlightSlot.mockReset().mockResolvedValue({});
    });

    it("saves the new title on enter", async () => {
      const wrapper = await mount([seat({ id: "comms" })]);

      await wrapper
        .find('[data-test="flight-wide-seat-title-comms"]')
        .trigger("click");
      const input = wrapper.find('[data-test="flight-wide-seat-edit-comms"]');
      await input.setValue("  Medic  ");
      await input.trigger("keydown", { key: "Enter" });
      await flushPromises();

      expect(api.updateFleetSquadronFlightSlot).toHaveBeenCalledOnce();
      expect(api.updateFleetSquadronFlightSlot).toHaveBeenCalledWith(
        "fleet",
        "alpha",
        "flight-1",
        "comms",
        { title: "Medic" },
      );
      expect(
        wrapper.find('[data-test="flight-wide-seat-edit-comms"]').exists(),
      ).toBe(false);
    });

    it("leaves the title alone on escape or when unchanged", async () => {
      const wrapper = await mount([seat({ id: "comms" })]);
      const title = '[data-test="flight-wide-seat-title-comms"]';
      const edit = '[data-test="flight-wide-seat-edit-comms"]';

      await wrapper.find(title).trigger("click");
      await wrapper.find(edit).setValue("Medic");
      await wrapper.find(edit).trigger("keydown", { key: "Escape" });

      await wrapper.find(title).trigger("click");
      await wrapper.find(edit).trigger("blur");
      await flushPromises();

      expect(api.updateFleetSquadronFlightSlot).not.toHaveBeenCalled();
    });

    it("sends one request when the enter is followed by a blur", async () => {
      const wrapper = await mount([seat({ id: "comms" })]);

      await wrapper
        .find('[data-test="flight-wide-seat-title-comms"]')
        .trigger("click");
      const input = wrapper.find('[data-test="flight-wide-seat-edit-comms"]');
      await input.setValue("Medic");
      await input.trigger("keydown", { key: "Enter" });
      await input.trigger("blur");
      await flushPromises();

      expect(api.updateFleetSquadronFlightSlot).toHaveBeenCalledOnce();
    });

    it("keeps the typed title open when the save fails", async () => {
      api.updateFleetSquadronFlightSlot.mockRejectedValue(new Error("nope"));
      const wrapper = await mount([seat({ id: "comms" })]);

      await wrapper
        .find('[data-test="flight-wide-seat-title-comms"]')
        .trigger("click");
      const input = wrapper.find('[data-test="flight-wide-seat-edit-comms"]');
      await input.setValue("Medic");
      await input.trigger("keydown", { key: "Enter" });
      await flushPromises();

      const stillOpen = wrapper.find(
        '[data-test="flight-wide-seat-edit-comms"]',
      );
      expect(stillOpen.exists()).toBe(true);
      expect((stillOpen.element as HTMLInputElement).value).toBe("Medic");
    });

    it("does not save on the enter that picks an IME candidate", async () => {
      const wrapper = await mount([seat({ id: "comms" })]);

      await wrapper
        .find('[data-test="flight-wide-seat-title-comms"]')
        .trigger("click");
      const input = wrapper.find('[data-test="flight-wide-seat-edit-comms"]');
      await input.setValue("Medic");
      await input.trigger("keydown", { key: "Enter", isComposing: true });
      await flushPromises();

      expect(api.updateFleetSquadronFlightSlot).not.toHaveBeenCalled();
      expect(input.exists()).toBe(true);
    });

    it("leaves the next rename open when an earlier save returns", async () => {
      let finish = () => {};
      api.updateFleetSquadronFlightSlot.mockReturnValue(
        new Promise<void>((resolve) => (finish = resolve)),
      );
      const wrapper = await mount([
        seat({ id: "comms" }),
        seat({ id: "medic", title: "Medic" }),
      ]);

      await wrapper
        .find('[data-test="flight-wide-seat-title-comms"]')
        .trigger("click");
      const comms = wrapper.find('[data-test="flight-wide-seat-edit-comms"]');
      await comms.setValue("Scout");
      await comms.trigger("keydown", { key: "Enter" });
      await comms.trigger("blur");

      await wrapper
        .find('[data-test="flight-wide-seat-title-medic"]')
        .trigger("click");
      await wrapper
        .find('[data-test="flight-wide-seat-edit-medic"]')
        .setValue("Doc");

      finish();
      await flushPromises();

      const medic = wrapper.find('[data-test="flight-wide-seat-edit-medic"]');
      expect(medic.exists()).toBe(true);
      expect((medic.element as HTMLInputElement).value).toBe("Doc");
    });

    it("does not offer to rename the lead seat", async () => {
      const wrapper = await mount([
        seat({ id: "lead", title: "Flight lead", lead: true }),
      ]);

      expect(
        wrapper.find('[data-test="flight-wide-seat-title-lead"]').exists(),
      ).toBe(false);
    });
  });
});
