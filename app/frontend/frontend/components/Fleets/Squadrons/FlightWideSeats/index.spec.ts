import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import { type MissionSlot, MissionSlottableTypeEnum } from "@/services/fyApi";

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
});
