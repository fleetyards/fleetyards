import { describe, expect, it } from "vitest";
import { packGrid } from "./CargoContainers";

const scu = (placements: ReturnType<typeof packGrid>) =>
  placements.reduce((sum, placement) => sum + placement.size, 0);

describe("packGrid", () => {
  it("fills a grid with the largest containers first", () => {
    const placements = packGrid(8, 2, 2);

    expect(placements).toEqual([
      { size: 32, x: 0, y: 0, z: 0, cx: 8, cy: 2, cz: 2 },
    ]);
  });

  it("fills every cell of a grid that no single container matches", () => {
    // The Caterpillar's module grid: 4 x 6 cells, 4 high.
    const placements = packGrid(4, 6, 4);

    expect(scu(placements)).toBe(96);
    expect(placements.every((placement) => placement.size === 24)).toBe(true);
  });

  it("keeps to the largest container a grid takes", () => {
    expect(packGrid(8, 2, 2, 16).map((placement) => placement.size)).toEqual([
      16, 16,
    ]);
  });

  it("places nothing in a grid under one cell", () => {
    expect(packGrid(0, 3, 3)).toEqual([]);
  });
});
