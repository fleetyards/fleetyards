import { describe, expect, it } from "vitest";
import {
  LocationKindEnum,
  type LocationJumpPoint,
  type LocationStarmapPlace,
} from "@/services/fyApi";
import type { QuantumRoute } from "@/frontend/utils/quantumRoute";
import { legsInSystem, tunnelsOf } from "./route";

const jumpPoint = (
  id: string,
  systemId: string,
  destinationSystemId: string | null,
): LocationJumpPoint => ({
  location: {
    id,
    slug: id,
    name: id,
    kind: LocationKindEnum.JUMP_POINT,
    parentName: null,
  },
  systemId,
  destinationName: destinationSystemId ?? "",
  destinationSystemId,
  temporary: false,
});

const place = (
  id: string,
  kind: LocationKindEnum,
  position: number[],
): LocationStarmapPlace =>
  ({ id, slug: id, name: id, kind, position }) as LocationStarmapPlace;

describe("tunnelsOf", () => {
  it("joins each jump point to the one leading back", () => {
    expect(
      tunnelsOf([
        jumpPoint("stanton-pyro", "stanton", "pyro"),
        jumpPoint("pyro-stanton", "pyro", "stanton"),
        jumpPoint("pyro-nyx", "pyro", "nyx"),
      ]),
    ).toEqual([
      { from: "stanton-pyro", to: "pyro-stanton" },
      { from: "pyro-stanton", to: "stanton-pyro" },
    ]);
  });

  it("leaves a jump point without a known destination unjoined", () => {
    expect(tunnelsOf([jumpPoint("lost", "stanton", null)])).toEqual([]);
  });
});

describe("legsInSystem", () => {
  const star = place("star", LocationKindEnum.STAR, [1e9, 0, 0]);
  const a = place("a", LocationKindEnum.STATION, [1e9, 2e9, 0]);
  const b = place("b", LocationKindEnum.STATION, [3e9, 0, 1e6]);
  const gate = place("gate", LocationKindEnum.JUMP_POINT, [0, 0, 0]);

  const route: QuantumRoute = {
    legs: [
      {
        kind: "quantum",
        from: a,
        to: b,
        systemId: "one",
        distance: 0,
        spool: 0,
        travel: 0,
        fuel: 0,
        refuel: false,
      },
      { kind: "tunnel", from: b, to: gate },
      {
        kind: "quantum",
        from: gate,
        to: a,
        systemId: "two",
        distance: 0,
        spool: 0,
        travel: 0,
        fuel: 0,
        refuel: false,
      },
    ],
    distance: 0,
    time: 0,
    fuel: 0,
    exceedsTank: false,
  };

  it("draws the system's own jumps from its star, in scene units", () => {
    expect(legsInSystem(route, { id: "one", places: [star, a, b] })).toEqual([
      [
        [0, 0, -2000],
        [2000, 1, 0],
      ],
    ]);
  });

  it("draws nothing without a route", () => {
    expect(legsInSystem(null, { id: "one", places: [star] })).toEqual([]);
  });
});
