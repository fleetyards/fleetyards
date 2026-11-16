import { describe, expect, it } from "vitest";
import type { CargoHold } from "@/services/fyApi";
import { groupCargoHolds } from "./grouping";

const hold = (name: string, overrides: Partial<CargoHold> = {}): CargoHold =>
  ({
    name,
    dimensions: { x: 5, y: 7.5, z: 5 },
    capacity: 96,
    maxContainerSize: { size: 32, dimensions: { x: 10, y: 2.5, z: 2.5 } },
    limits: {
      min: { dimensions: { x: 1.25, y: 1.25, z: 1.25 }, capacity: 1 },
      max: { dimensions: { x: 10, y: 2.5, z: 2.5 }, capacity: 32 },
    },
    ...overrides,
  }) as CargoHold;

// The Caterpillar: two modules of three holds each.
const names = [
  "hardpoint_cargogrid_module_01",
  "hardpoint_cargogrid_module_01_ladder",
  "hardpoint_cargogrid_module_01_walkway",
  "hardpoint_cargogrid_module_02",
  "hardpoint_cargogrid_module_02_ladder",
  "hardpoint_cargogrid_module_02_walkway",
];

describe("groupCargoHolds", () => {
  it("keeps hand-placed modules apart, each laid out on its own", () => {
    const holds = names.map((name) =>
      hold(name, { offset: { x: 0, y: 0, z: 0 } }),
    );

    expect(groupCargoHolds(holds)).toHaveLength(2);
  });

  it("lays a ship the export placed out as one, as its holds sit in it", () => {
    const holds = names.map((name, index) =>
      hold(name, { offset: { x: index * 10, y: 0, z: 0 }, placed: true }),
    );

    const groups = groupCargoHolds(holds);

    expect(groups).toHaveLength(1);
    expect(groups[0].holdIndices).toEqual([0, 1, 2, 3, 4, 5]);
  });
});
