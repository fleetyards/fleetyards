import { globeStyle } from "@/shared/utils/LocationGlobe";

describe("globeStyle", () => {
  it("shades the colour like a lit sphere", () => {
    expect(
      globeStyle({ kind: "moon", color: "#a0522d" })?.backgroundImage,
    ).toMatch(/^radial-gradient\(circle at 32% 28%.*#a0522d/);
  });

  it("leaves the circle to its stylesheet without a colour", () => {
    expect(globeStyle({ kind: "planet", color: null })).toBeUndefined();
    expect(globeStyle(undefined)).toBeUndefined();
  });

  it("draws no sphere for a place that is not a body", () => {
    expect(globeStyle({ kind: "station", color: "#a0522d" })).toBeUndefined();
    expect(globeStyle({ kind: "star", color: "#a0522d" })).toBeUndefined();
  });
});
