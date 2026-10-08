import { afterEach, describe, expect, it, vi } from "vitest";
import { isMobileWidth } from "./mobile";

// What a browser answers at a given viewport width: the media query measures
// the viewport including its scrollbar, and its bound is inclusive.
const viewport = (width: number) => {
  const matchMedia = vi.fn((query: string) => ({
    matches: query === "(max-width: 992px)" && width <= 992,
  }));
  vi.stubGlobal("matchMedia", matchMedia);
  return matchMedia;
};

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("isMobileWidth", () => {
  it("asks the navigation stylesheets' own media query", () => {
    const matchMedia = viewport(1200);

    isMobileWidth();

    expect(matchMedia).toHaveBeenCalledWith("(max-width: 992px)");
  });

  it("counts 992px itself as mobile", () => {
    viewport(992);

    expect(isMobileWidth()).toBe(true);
  });

  // jsdom reads the document 0 wide, which the old width check took for a
  // phone; the media query answers for the viewport.
  it("reads a wider viewport as desktop", () => {
    viewport(993);

    expect(isMobileWidth()).toBe(false);
  });
});
