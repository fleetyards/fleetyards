import { beforeEach, describe, expect, it, vi } from "vitest";

const calls: { name: string; args: unknown[] }[] = [];

vi.mock("@/services/fyApi", () => {
  const record =
    (name: string) =>
    (...args: unknown[]) => {
      calls.push({ name, args });
      return Promise.resolve({});
    };

  return {
    createMissionShip: record("createMissionShip"),
    createFleetSquadronFlightShip: record("createFleetSquadronFlightShip"),
    destroyMissionSlot: record("destroyMissionSlot"),
    destroyFleetSquadronFlightSlot: record("destroyFleetSquadronFlightSlot"),
    sortMissionShips: record("sortMissionShips"),
    sortFleetSquadronFlightShips: record("sortFleetSquadronFlightShips"),
  };
});

const { useLineupApi } = await import("./useLineupApi");

describe("useLineupApi", () => {
  beforeEach(() => {
    calls.length = 0;
  });

  it("addresses a template team by its mission", async () => {
    const api = useLineupApi({
      fleetSlug: "fleet",
      missionSlug: "op",
      teamId: "team-1",
    });

    await api.createShip({ classification: "Combat" } as never);
    await api.destroySlot("slot-1");

    expect(calls).toEqual([
      {
        name: "createMissionShip",
        args: ["fleet", "op", "team-1", { classification: "Combat" }],
      },
      { name: "destroyMissionSlot", args: ["slot-1"] },
    ]);
  });

  it("addresses a flight's team through its squadron", async () => {
    const api = useLineupApi({
      fleetSlug: "fleet",
      squadronSlug: "alpha",
      flightId: "flight-1",
      teamId: "team-1",
    });

    await api.sortShips(["b", "a"]);
    await api.destroySlot("slot-1");

    expect(calls).toEqual([
      {
        name: "sortFleetSquadronFlightShips",
        args: ["fleet", "alpha", "flight-1", { sorting: ["b", "a"] }],
      },
      {
        name: "destroyFleetSquadronFlightSlot",
        args: ["fleet", "alpha", "flight-1", "slot-1"],
      },
    ]);
  });

  it("is pending while a request is in flight", async () => {
    const api = useLineupApi({ fleetSlug: "fleet", teamId: "team-1" });

    const request = api.destroySlot("slot-1");
    expect(api.isPending.value).toBe(true);

    await request;
    expect(api.isPending.value).toBe(false);
  });
});
