import { describe, expect, it } from "vitest";
import { BoxGeometry, Vector3 } from "three";
import { surfaceArea, surfaceLayers } from "./surfaceArea";

describe("surfaceArea", () => {
  it("adds up a geometry's faces", () => {
    expect(surfaceArea(new BoxGeometry(1, 2, 3))).toBeCloseTo(22);
  });
});

describe("surfaceLayers", () => {
  it("is one for a plain shell", () => {
    expect(surfaceLayers(22, new Vector3(1, 2, 3))).toBeCloseTo(1);
  });

  it("counts the surface inside a shell", () => {
    expect(surfaceLayers(66, new Vector3(1, 2, 3))).toBeCloseTo(3);
  });

  it("never drops below one", () => {
    expect(surfaceLayers(5, new Vector3(1, 2, 3))).toBe(1);
  });
});
