import { describe, expect, it } from "vitest";
import {
  LocationKindEnum,
  type ComponentQuantumDrive,
  type LocationStarmapPlace,
} from "@/services/fyApi";
import { clearsBody, planRoute, type RouteDrive } from "./quantumRoute";

const place = (
  overrides: Partial<LocationStarmapPlace> & { id: string },
): LocationStarmapPlace =>
  ({
    name: overrides.id,
    slug: overrides.id,
    kind: LocationKindEnum.STATION,
    parentName: null,
    parentId: null,
    position: [0, 0, 0],
    radius: null,
    shownOnStarmap: true,
    shownWithParentOnly: false,
    alwaysShown: false,
    quantumTravelDestination: true,
    lagrangePoint: false,
    gateway: false,
    color: null,
    unstable: false,
    bodyType: null,
    ...overrides,
  }) as LocationStarmapPlace;

const GM = 1e9;

const drive = (overrides: Partial<ComponentQuantumDrive> = {}): RouteDrive => ({
  typeData: {
    driveSpeed: 283046000,
    stageOneAccelRate: 49500000,
    stageTwoAccelRate: 1500000,
    spoolUpTime: 5,
    cooldownTime: 10,
    quantumFuelConsumption: 5,
    ...overrides,
  },
  tankSize: 1,
});

const planet = place({
  id: "planet",
  kind: LocationKindEnum.PLANET,
  position: [10 * GM, 0, 0],
  radius: 1e6,
  quantumTravelDestination: false,
});

describe("clearsBody", () => {
  const body = { id: "b", position: [0, 0, 0], radius: 100 };

  it("refuses a line through the body", () => {
    expect(clearsBody([-500, 0, 0], [500, 0, 0], body)).toBe(false);
  });

  it("refuses a line inside the margin", () => {
    expect(clearsBody([-500, 104, 0], [500, 104, 0], body)).toBe(false);
  });

  it("allows a line that passes outside the margin", () => {
    expect(clearsBody([-500, 106, 0], [500, 106, 0], body)).toBe(true);
  });

  it("allows a line that ends short of the body", () => {
    expect(clearsBody([-500, 0, 0], [-200, 0, 0], body)).toBe(true);
  });
});

describe("planRoute", () => {
  it("jumps straight there when nothing is in the way", () => {
    const a = place({ id: "a", position: [0, 5 * GM, 0] });
    const b = place({ id: "b", position: [20 * GM, 5 * GM, 0] });

    const route = planRoute({
      systems: [{ id: "s", places: [planet, a, b] }],
      drive: drive(),
      from: "a",
      to: "b",
    });

    expect(route?.legs.map((leg) => leg.to.id)).toEqual(["b"]);
    expect(route?.distance).toBeCloseTo(20 * GM);
  });

  it("goes round a planet in the way through another destination", () => {
    const a = place({ id: "a", position: [0, 0, 0] });
    const b = place({ id: "b", position: [20 * GM, 0, 0] });
    const detour = place({ id: "detour", position: [10 * GM, 3 * GM, 0] });

    const route = planRoute({
      systems: [{ id: "s", places: [planet, a, b, detour] }],
      drive: drive(),
      from: "a",
      to: "b",
    });

    expect(route?.legs.map((leg) => leg.to.id)).toEqual(["detour", "b"]);
  });

  it("jumps to a planet in the way and on from its far side", () => {
    const a = place({ id: "a", position: [0, 0, 0] });
    const b = place({ id: "b", position: [20 * GM, 0, 0] });

    const route = planRoute({
      systems: [
        {
          id: "s",
          places: [{ ...planet, quantumTravelDestination: true }, a, b],
        },
      ],
      drive: drive(),
      from: "a",
      to: "b",
    });

    expect(route?.legs.map((leg) => leg.to.id)).toEqual(["planet", "b"]);
  });

  it("finds no route when every line is blocked", () => {
    const a = place({ id: "a", position: [0, 0, 0] });
    const b = place({ id: "b", position: [20 * GM, 0, 0] });

    expect(
      planRoute({
        systems: [{ id: "s", places: [planet, a, b] }],
        drive: drive(),
        from: "a",
        to: "b",
      }),
    ).toBeNull();
  });

  describe("from a place on a planet's surface", () => {
    const b = place({ id: "b", position: [0, 0, 0] });
    const plan = (outpostX: number, planetIsDestination: boolean) =>
      planRoute({
        systems: [
          {
            id: "s",
            places: [
              { ...planet, quantumTravelDestination: planetIsDestination },
              place({
                id: "outpost",
                kind: LocationKindEnum.OUTPOST,
                position: [10 * GM + outpostX, 0, 0],
              }),
              b,
            ],
          },
        ],
        drive: drive(),
        from: "outpost",
        to: "b",
      });

    it("jumps straight to what is above its horizon", () => {
      expect(plan(-1e6, false)?.legs.map((leg) => leg.to.id)).toEqual(["b"]);
    });

    it("cannot jump through its own planet", () => {
      expect(plan(1e6, false)).toBeNull();
    });

    it("reaches what is below its horizon through the planet", () => {
      expect(plan(1e6, true)?.legs.map((leg) => leg.to.id)).toEqual([
        "planet",
        "b",
      ]);
    });
  });

  it("treats a place inside a station as the station", () => {
    const a = place({ id: "a", position: [0, 0, 0] });
    const b = place({ id: "b", position: [20 * GM, 0, 0] });
    const detour = place({ id: "detour", position: [10 * GM, 3 * GM, 0] });
    const clinic = place({
      id: "clinic",
      kind: LocationKindEnum.CLINIC,
      position: [10 * GM, 3 * GM + 5000, 0],
    });

    const route = planRoute({
      systems: [{ id: "s", places: [planet, a, b, detour, clinic] }],
      drive: drive(),
      from: "a",
      to: "b",
    });

    expect(route?.legs.map((leg) => leg.to.id)).toEqual(["detour", "b"]);
  });

  it("does not stop at places that are not quantum destinations", () => {
    const a = place({ id: "a", position: [0, 0, 0] });
    const b = place({ id: "b", position: [20 * GM, 0, 0] });
    const wreck = place({
      id: "wreck",
      position: [10 * GM, 3 * GM, 0],
      quantumTravelDestination: false,
    });

    expect(
      planRoute({
        systems: [{ id: "s", places: [planet, a, b, wreck] }],
        drive: drive(),
        from: "a",
        to: "b",
      }),
    ).toBeNull();
  });

  it("adds spool to every jump and cooldown between them", () => {
    const a = place({ id: "a", position: [0, 0, 0] });
    const b = place({ id: "b", position: [20 * GM, 0, 0] });
    const detour = place({ id: "detour", position: [10 * GM, 3 * GM, 0] });

    const route = planRoute({
      systems: [{ id: "s", places: [planet, a, b, detour] }],
      drive: drive(),
      from: "a",
      to: "b",
    })!;
    const travel = route.legs.reduce(
      (sum, leg) => sum + (leg.kind === "quantum" ? leg.travel : 0),
      0,
    );

    expect(route.time).toBeCloseTo(travel + 2 * 5 + 10);
  });

  it("burns fuel per gigametre and flags a tank too small", () => {
    const a = place({ id: "a", position: [0, 5 * GM, 0] });
    const b = place({ id: "b", position: [20 * GM, 5 * GM, 0] });
    const plan = (consumption: number) =>
      planRoute({
        systems: [{ id: "s", places: [planet, a, b] }],
        drive: drive({ quantumFuelConsumption: consumption }),
        from: "a",
        to: "b",
      })!;

    expect(plan(5).fuel).toBeCloseTo(0.1);
    expect(plan(5).exceedsTank).toBe(false);
    expect(plan(60).exceedsTank).toBe(true);
  });

  it("crosses into another system through a tunnel", () => {
    const a = place({ id: "a", position: [0, 5 * GM, 0] });
    const gate = place({
      id: "gate",
      kind: LocationKindEnum.JUMP_POINT,
      position: [30 * GM, 0, 0],
      quantumTravelDestination: false,
    });
    const otherGate = place({
      id: "other-gate",
      kind: LocationKindEnum.JUMP_POINT,
      position: [-30 * GM, 0, 0],
      quantumTravelDestination: false,
    });
    const b = place({ id: "b", position: [0, 0, 0] });

    const route = planRoute({
      systems: [
        { id: "one", places: [a, gate] },
        { id: "two", places: [otherGate, b] },
      ],
      tunnels: [{ from: "gate", to: "other-gate" }],
      drive: drive(),
      from: "a",
      to: "b",
    })!;

    expect(route.legs.map((leg) => [leg.kind, leg.to.id])).toEqual([
      ["quantum", "gate"],
      ["tunnel", "other-gate"],
      ["quantum", "b"],
    ]);
    expect(route.distance).toBeCloseTo(Math.hypot(30, 5) * GM + 30 * GM);
  });

  it("never jumps between systems outside a tunnel", () => {
    const a = place({ id: "a", position: [0, 0, 0] });
    const b = place({ id: "b", position: [1 * GM, 0, 0] });

    expect(
      planRoute({
        systems: [
          { id: "one", places: [a] },
          { id: "two", places: [b] },
        ],
        drive: drive(),
        from: "a",
        to: "b",
      }),
    ).toBeNull();
  });
});
