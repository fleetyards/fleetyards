import { parallaxOffset } from "@/shared/composables/useParallax";

describe("parallaxOffset", () => {
  it("is zero while the section is centred in the viewport", () => {
    expect(parallaxOffset(100, 600, 800, 0.25)).toBeCloseTo(0);
  });

  it("moves against the scroll as the section leaves the centre", () => {
    expect(parallaxOffset(500, 600, 800, 0.25)).toBe(-100);
    expect(parallaxOffset(-300, 600, 800, 0.25)).toBe(100);
  });
});
