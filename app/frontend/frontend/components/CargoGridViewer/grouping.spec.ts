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
  it("groups holds no export placed by their names", () => {
    const groups = groupCargoHolds(names.map((name) => hold(name)));

    expect(groups.map((group) => group.holdIndices)).toEqual([
      [0, 1, 2],
      [3, 4, 5],
    ]);
    expect(groups.every((group) => !group.placed)).toBe(true);
  });

  it("lays a ship the export placed out as one, as its holds sit in it", () => {
    const holds = names.map((name, index) =>
      hold(name, {
        position: [index * 10, 0, 0],
        orientation: [0, 0, 0, 1],
        placedIn: "model/drak-caterpillar",
      }),
    );

    const groups = groupCargoHolds(holds);

    expect(groups).toHaveLength(1);
    expect(groups[0].placed).toBe(true);
    expect(groups[0].holdIndices).toEqual([0, 1, 2, 3, 4, 5]);
  });

  it("keeps a ship and each module fitted to it in their own frames", () => {
    const holds = [
      hold("hardpoint_cargo_bay", {
        position: [0, 0, 0],
        orientation: [0, 0, 0, 1],
        placedIn: "model/rsi-galaxy",
      }),
      hold("hardpoint_cargo_grid_left", {
        position: [0, 0, 0],
        orientation: [0, 0, 0, 1],
        placedIn: "model_module/cargo-module",
      }),
      hold("hardpoint_cargo_grid_right", {
        position: [0, 10, 0],
        orientation: [0, 0, 0, 1],
        placedIn: "model_module/cargo-module",
      }),
      hold("cargo_front"),
    ];

    const groups = groupCargoHolds(holds);

    expect(groups.map((group) => [group.holdIndices, group.placed])).toEqual([
      [[0], true],
      [[1, 2], true],
      [[3], false],
    ]);
  });

  it("keeps a module fitted twice in two frames", () => {
    const module = (name: string) =>
      hold(name, {
        position: [0, 0, 0],
        orientation: [0, 0, 0, 1],
        placedIn: "model_module/cargo-module",
      });
    const holds = [
      module("hardpoint_cargo_grid_left"),
      module("hardpoint_cargo_grid_right"),
      module("hardpoint_cargo_grid_left"),
      module("hardpoint_cargo_grid_right"),
    ];

    expect(groupCargoHolds(holds).map((group) => group.holdIndices)).toEqual([
      [0, 1],
      [2, 3],
    ]);
  });
});
