import { describe, expect, it } from "vitest";
import type { CargoHold } from "@/services/fyApi";
import { holdPlacement } from "./placement";

const STRAIGHT = [0, 0, 0, 1];
const QUARTER = [0, -Math.SQRT1_2, 0, Math.SQRT1_2];

const hold = (
  position: number[],
  rotation: number[],
  dimensions: { x: number; y: number; z: number },
) => ({ position, rotation, dimensions }) as CargoHold;

const rounded = (offset: { x: number; y: number; z: number }) =>
  [offset.x, offset.y, offset.z].map(
    (value) => Math.round(value * 1000) / 1000,
  );

describe("holdPlacement", () => {
  it("turns a grid the export leaves straight a quarter onto the floor", () => {
    // The Galaxy cargo module's left grid.
    const placed = holdPlacement(
      hold([-10.1, -0.5, 4.5], STRAIGHT, { x: 5, y: 20, z: 5 }),
    );

    expect(placed?.turned).toBe(true);
    expect(rounded(placed!.offset)).toEqual([-14.5, -12.6, -3]);
  });

  it("lays a grid the export turns a quarter along the floor", () => {
    // The Caterpillar's fourth module beside its walkway.
    const module = holdPlacement(
      hold([0.625, -0.25, -2.625], QUARTER, { x: 5, y: 7.5, z: 5 }),
    )!;
    const walkway = holdPlacement(
      hold([-3.75, -1.5, -2.625], QUARTER, { x: 5, y: 1.25, z: 2.5 }),
    )!;

    expect(module.turned).toBe(false);
    expect(
      rounded({
        x: module.offset.x - walkway.offset.x,
        y: module.offset.y - walkway.offset.y,
        z: module.offset.z - walkway.offset.z,
      }),
    ).toEqual([0, 1.25, 0]);
  });

  it("places nothing without the export's values", () => {
    expect(
      holdPlacement({ dimensions: { x: 1, y: 1, z: 1 } } as CargoHold),
    ).toBeUndefined();
  });
});
