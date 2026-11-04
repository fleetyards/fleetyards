import { describe, expect, it } from "vitest";
import { Vector3 } from "three";
import { gridScale } from "./gridScale";

describe("gridScale", () => {
  it("leaves a holo already at its length alone, whatever its beam", () => {
    expect(gridScale(new Vector3(12.03, 3.26, 17.79), 17.79)).toBe(1);
  });

  it("measures a ship wider than it is long along its length", () => {
    expect(gridScale(new Vector3(62.51, 27.37, 52.69), 52.69)).toBe(1);
  });

  it("scales a holo in other units to its length", () => {
    expect(gridScale(new Vector3(30, 5, 100), 25)).toBe(0.25);
  });
});
