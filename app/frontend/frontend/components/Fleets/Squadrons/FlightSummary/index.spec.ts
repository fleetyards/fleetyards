import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import {
  type FleetSquadronFlight,
  type MediaFile,
  type MissionShip,
} from "@/services/fyApi";

const shipWithRender = (id: string, url: string): MissionShip =>
  ({
    id,
    missionTeamId: "team-1",
    position: 0,
    strict: false,
    allowedModels: [],
    slots: [],
    model: { angledView: { mediumUrl: url } },
  }) as unknown as MissionShip;

const flight = (
  overrides: Partial<FleetSquadronFlight> = {},
): FleetSquadronFlight =>
  ({
    id: "flight-1",
    name: "Strike",
    shortDescription: null,
    description: null,
    position: 0,
    teamId: "team-1",
    coverImage: null,
    slots: [],
    ships: [],
    createdAt: "2026-11-13T00:00:00Z",
    updatedAt: "2026-11-13T00:00:00Z",
    ...overrides,
  }) as FleetSquadronFlight;

const mount = (value: FleetSquadronFlight) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { flight: value, to: "/flights/flight-1" },
  });

const cover = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.find('[data-test="flight-summary-cover"]');

describe("FleetSquadronFlightSummary", () => {
  it("shows the uploaded cover over the first ship", async () => {
    const wrapper = await mount(
      flight({
        coverImage: {
          url: "/cover.png",
          largeUrl: "/cover-large.png",
        } as MediaFile,
        ships: [shipWithRender("ship-1", "/ship.png")],
      }),
    );

    expect(cover(wrapper).find("img").attributes("src")).toBe(
      "/cover-large.png",
    );
    expect(cover(wrapper).classes()).not.toContain(
      "flight-summary__cover--render",
    );
  });

  it("falls back to the first ship in the lineup", async () => {
    const wrapper = await mount(
      flight({
        ships: [
          shipWithRender("ship-1", "/first.png"),
          shipWithRender("ship-2", "/second.png"),
        ],
      }),
    );

    expect(cover(wrapper).find("img").attributes("src")).toBe("/first.png");
    expect(cover(wrapper).classes()).toContain("flight-summary__cover--render");
  });

  it("skips an upload that is not an image and a ship without a picture", async () => {
    const wrapper = await mount(
      flight({
        coverImage: { url: "/notes.pdf" } as MediaFile,
        ships: [
          { ...shipWithRender("ship-1", ""), model: undefined } as MissionShip,
          shipWithRender("ship-2", "/second.png"),
        ],
      }),
    );

    expect(cover(wrapper).find("img").attributes("src")).toBe("/second.png");
  });

  it("shows no image without a cover or a ship", async () => {
    const wrapper = await mount(flight());

    expect(cover(wrapper).exists()).toBe(false);
  });

  it("shows the short description only when there is one", async () => {
    const withText = await mount(
      flight({ shortDescription: "Escorts the haulers" }),
    );
    const without = await mount(flight({ description: "**Long** text" }));

    expect(
      withText.find('[data-test="flight-summary-description"]').text(),
    ).toBe("Escorts the haulers");
    expect(
      without.find('[data-test="flight-summary-description"]').exists(),
    ).toBe(false);
  });
});
