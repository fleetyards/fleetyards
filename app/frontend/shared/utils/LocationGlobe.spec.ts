import { globeStyle } from "@/shared/utils/LocationGlobe";

describe("globeStyle", () => {
  it("fills the circle with the picture before the colour", () => {
    const style = globeStyle({
      color: "#a0522d",
      image: {
        url: "https://cdn.test/hurston.png",
        smallUrl: "https://cdn.test/hurston-small.png",
      },
    });

    expect(style?.backgroundImage).toBe(
      'url("https://cdn.test/hurston-small.png")',
    );
    expect(style?.backgroundSize).toBe("cover");
  });

  it("shades the colour like a lit sphere", () => {
    expect(globeStyle({ color: "#a0522d" })?.backgroundImage).toMatch(
      /^radial-gradient\(circle at 32% 28%.*#a0522d/,
    );
  });

  it("leaves the circle to its stylesheet without either", () => {
    expect(globeStyle({ color: null, image: null })).toBeUndefined();
    expect(globeStyle(undefined)).toBeUndefined();
  });
});
