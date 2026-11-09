import { describe, expect, it } from "vitest";
import {
  compositeEyeTexel,
  compositeHeadTexel,
  hexLinear,
  hueRotation,
  linearToSrgb,
  srgbToLinear,
} from "./materials";
import type { EyeRecipe, HeadRecipe } from "./types";
import fixtures from "./materials.fixtures.json";

// From the published test vectors: each texture a head recipe names, sampled
// where the reference's 512 px composite was sampled, and what it gave there.
type Fixture = {
  recipe: HeadRecipe;
  texels: Record<string, Record<string, number[]>>;
  expected: Record<string, number[]>;
  eyes: EyeRecipe;
};

describe("compositeHeadTexel", () => {
  for (const [name, fixture] of Object.entries(
    fixtures as unknown as Record<string, Fixture>,
  )) {
    it(`composites ${name}'s head as the reference does`, () => {
      Object.entries(fixture.expected).forEach(([point, expected]) => {
        const texels = fixture.texels[point];
        const got = compositeHeadTexel(fixture.recipe, (url) => texels[url]);

        got.forEach((value, c) =>
          expect(Math.abs(value - expected[c])).toBeLessThan(1 / 255),
        );
      });
    });
  }
});

describe("compositeEyeTexel", () => {
  it("shows the sclera where the iris is transparent and the tinted iris where it is not", () => {
    const recipe: EyeRecipe = {
      iris: "iris.webp",
      iris_color: "#7b6b00",
      sclera: "#d9d0c8",
    };

    expect(
      compositeEyeTexel(recipe, [1, 1, 1, 0]).map((c) => Math.round(c * 255)),
    ).toEqual([217, 208, 200]);
    const tint = hexLinear("#7b6b00").map((c) =>
      linearToSrgb(Math.min(c * 1.6, 1)),
    );
    compositeEyeTexel(recipe, [1, 1, 1, 1]).forEach((c, i) =>
      expect(c).toBeCloseTo(tint[i], 6),
    );
  });
});

describe("colour helpers", () => {
  it("round-trips sRGB through linear", () => {
    [0, 0.02, 0.5, 1].forEach((c) =>
      expect(linearToSrgb(srgbToLinear(c))).toBeCloseTo(c, 9),
    );
  });

  it("leaves colours alone at no hue turn and after a full one", () => {
    [0, 1].forEach((turns) =>
      hueRotation(turns).forEach((row, i) =>
        row.forEach((value, j) =>
          expect(value).toBeCloseTo(i === j ? 1 : 0, 9),
        ),
      ),
    );
  });
});
