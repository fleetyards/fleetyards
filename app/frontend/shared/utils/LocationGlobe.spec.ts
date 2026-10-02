import { globeStyle } from "@/shared/utils/LocationGlobe";

describe("globeStyle", () => {
  it("hands the colour to the globe", () => {
    expect(globeStyle({ kind: "moon", color: "#a0522d" })).toEqual({
      "--globe-color": "#a0522d",
      "--globe-border": "transparent",
    });
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
