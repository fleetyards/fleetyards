import { describe, expect, it } from "vitest";
import {
  VEHICLE_SEGMENT_PATTERN,
  gameSerial,
  vehicleIdentifierFromSegment,
  vehicleSegment,
} from "./vehicleSegment";

const id = "3f2a9c1e-1111-2222-3333-444455556666";

describe("vehicleSegment", () => {
  it("pairs the serial with the name", () => {
    expect(
      vehicleSegment({ id, serial: "L8-4261-HA", name: "USCS Tanngnjóstr" }),
    ).toBe("l8-4261-ha-uscs-tanngnjostr");
  });

  it("pairs the id with the name when there is no serial", () => {
    expect(vehicleSegment({ id, name: "Vulture" })).toBe(`${id}-vulture`);
  });

  it("pairs the serial with the id when there is no name", () => {
    expect(vehicleSegment({ id, serial: "L8-4261-HA" })).toBe(
      `l8-4261-ha-${id}`,
    );
  });

  it("is the id alone with neither", () => {
    expect(vehicleSegment({ id, name: null, serial: null })).toBe(id);
  });

  it("treats a serial from before the game format as no serial", () => {
    expect(
      vehicleSegment({ id, serial: "SUB FLAGSHIP", name: "Polaris" }),
    ).toBe(`${id}-polaris`);
  });

  it("drops a name with nothing left to put in a URL", () => {
    expect(vehicleSegment({ id, name: "铁锤号" })).toBe(id);
  });
});

describe("vehicleIdentifierFromSegment", () => {
  it("reads every shape back to what the API looks up", () => {
    const shapes = [
      { id, serial: "L8-4261-HA", name: "USCS Tanngnjostr" },
      { id, name: "Vulture" },
      { id, serial: "L8-4261-HA" },
      { id },
    ];

    expect(
      shapes.map((vehicle) =>
        vehicleIdentifierFromSegment(vehicleSegment(vehicle)),
      ),
    ).toEqual(["L8-4261-HA", id, "L8-4261-HA", id]);
  });

  it("ignores the name, even one that looks like an id", () => {
    expect(
      vehicleIdentifierFromSegment(`l8-4261-ha-${id.replace("3f", "aa")}`),
    ).toBe("L8-4261-HA");
  });

  it("finds nothing in a segment that leads with neither", () => {
    expect(vehicleIdentifierFromSegment("stats")).toBeUndefined();
    expect(vehicleIdentifierFromSegment("l8-4261-hax")).toBeUndefined();
  });
});

describe("VEHICLE_SEGMENT_PATTERN", () => {
  const pattern = new RegExp(`^(?:${VEHICLE_SEGMENT_PATTERN})$`, "i");

  it("matches every shape a vehicle can have", () => {
    expect(pattern.test("l8-4261-ha-uscs-tanngnjostr")).toBe(true);
    expect(pattern.test(`${id}-vulture`)).toBe(true);
    expect(pattern.test(id)).toBe(true);
  });

  it("leaves the public hangar's pages alone", () => {
    expect(pattern.test("stats")).toBe(false);
    expect(pattern.test("wishlist")).toBe(false);
    expect(pattern.test("fleetchart")).toBe(false);
  });
});

describe("gameSerial", () => {
  it("keeps only serials in the game format", () => {
    expect(gameSerial(" l8-4261-ha ")).toBe("L8-4261-HA");
    expect(gameSerial("l84261ha")).toBe("L8-4261-HA");
    expect(gameSerial("F-9")).toBeUndefined();
    expect(gameSerial(null)).toBeUndefined();
  });
});
