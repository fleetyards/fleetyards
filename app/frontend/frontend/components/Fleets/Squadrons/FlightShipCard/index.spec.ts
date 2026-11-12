import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import {
  type Fleet,
  type MissionShip,
  type MissionSlot,
  MissionSlottableTypeEnum,
} from "@/services/fyApi";

const seat = (id: string, filled: boolean, role?: string): MissionSlot => ({
  id,
  slottableType: MissionSlottableTypeEnum.MISSION_SHIP,
  slottableId: "ship-1",
  title: id,
  position: 0,
  derived: false,
  role: role as MissionSlot["role"],
  candidates: filled
    ? [
        {
          id: `${id}-c`,
          position: 0,
          username: `${id}-pilot`,
          passedAt: null,
          vehicle: null,
        },
      ]
    : [],
});

const ship = (slots: MissionSlot[]): MissionShip =>
  ({
    id: "ship-1",
    missionTeamId: "team-1",
    title: "Strike",
    position: 0,
    strict: false,
    allowedModels: [],
    slots,
  }) as MissionShip;

const mount = (slots: MissionSlot[], editable = false) =>
  mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "fleet" } as Fleet,
      scope: {
        fleetSlug: "fleet",
        squadronSlug: "alpha",
        flightId: "flight-1",
        teamId: "team-1",
      },
      ship: ship(slots),
      editable,
    },
  });

describe("FleetSquadronFlightShipCard", () => {
  it("lists up to five filled seats, captain and pilot first, and offers the rest", async () => {
    const wrapper = await mount([
      ...["a", "b", "c", "d", "e"].map((id) => seat(id, true)),
      seat("pilot", true, "pilot"),
      seat("captain", true, "captain"),
      seat("open", false),
    ]);

    const shown = wrapper
      .findAll(".flight-ship__seat")
      .map((row) => row.attributes("data-test"));

    expect(shown).toEqual([
      "flight-ship-seat-captain",
      "flight-ship-seat-pilot",
      "flight-ship-seat-a",
      "flight-ship-seat-b",
      "flight-ship-seat-c",
    ]);
    expect(wrapper.find('[data-test="flight-ship-more-seats"]').exists()).toBe(
      true,
    );
  });

  it("offers editing only to whoever may edit", async () => {
    const reader = await mount([seat("a", true)]);
    expect(reader.find(".flight-ship__actions").exists()).toBe(false);
    expect(reader.find(".flight-ship__seat-edit").exists()).toBe(false);

    const editor = await mount([seat("a", true)], true);
    expect(editor.find(".flight-ship__actions").exists()).toBe(true);
    expect(editor.find(".flight-ship__seat-edit").exists()).toBe(true);
  });
});
