import { describe, expect, it } from "vitest";
import { Vector3 } from "three";
import { backdropScale } from "./backdrop";

describe("backdropScale", () => {
  it("keeps the room as built around a standing figure", () => {
    expect(backdropScale(new Vector3(0.9, 1.85, 0.5))).toBe(1);
  });

  it("grows the room around a ship by its longest side", () => {
    expect(backdropScale(new Vector3(9, 4, 20))).toBe(8);
  });
});
