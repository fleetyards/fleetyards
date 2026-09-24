import { describe, expect, it } from "vitest";
import { keyColors } from "./KeyColors";

type Pixel = [number, number, number, number];

const pixels = (...runs: [Pixel, number][]) =>
  new Uint8ClampedArray(
    runs.flatMap(([pixel, times]) =>
      Array.from({ length: times }, () => pixel).flat(),
    ),
  );

const red: Pixel = [220, 30, 40, 255];
const blue: Pixel = [30, 60, 200, 255];
const white: Pixel = [250, 250, 250, 255];
const black: Pixel = [5, 5, 5, 255];
const clear: Pixel = [0, 200, 0, 0];

describe("keyColors", () => {
  it("ranks the colours by how much of the image they cover", () => {
    expect(keyColors(pixels([blue, 10], [red, 30]))).toEqual([
      "#dc1e28",
      "#1e3cc8",
    ]);
  });

  it("ignores the cut-out, the outline and the background", () => {
    expect(
      keyColors(pixels([clear, 100], [white, 50], [black, 50], [red, 5])),
    ).toEqual(["#dc1e28"]);
  });

  it("falls back to the greys when the emblem has nothing else", () => {
    expect(keyColors(pixels([black, 10], [clear, 50]))).toEqual(["#050505"]);
  });

  it("does not suggest two shades of the same colour", () => {
    const nearRed: Pixel = [228, 38, 48, 255];

    expect(keyColors(pixels([red, 30], [nearRed, 20], [blue, 5]))).toEqual([
      "#dc1e28",
      "#1e3cc8",
    ]);
  });

  it("returns nothing for a fully transparent image", () => {
    expect(keyColors(pixels([clear, 20]))).toEqual([]);
  });
});
