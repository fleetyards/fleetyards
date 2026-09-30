import { beforeEach, describe, expect, it } from "vitest";
import { placeFloating } from "./floatingPlacement";

const rect = (top: number, left: number, width = 100, height = 20) =>
  ({
    top,
    left,
    width,
    height,
    bottom: top + height,
    right: left + width,
  }) as DOMRect;

beforeEach(() => {
  Object.assign(window, { innerWidth: 1000, innerHeight: 800 });
});

describe("placeFloating", () => {
  it("centres a box below its anchor", () => {
    expect(
      placeFloating(rect(100, 400), { width: 200, height: 50 }, "bottom"),
    ).toEqual({ placement: "bottom", top: 128, left: 350 });
  });

  it("treats a placement it does not know as top, as the tooltip always has", () => {
    expect(
      placeFloating(rect(100, 400), { width: 200, height: 50 }, "sideways"),
    ).toMatchObject({ placement: "top", top: 42 });
  });

  it("slides a box back inside the viewport instead of shrinking it", () => {
    const { left } = placeFloating(
      rect(100, 950),
      { width: 200, height: 50 },
      "bottom",
      { margin: 8 },
    );

    expect(left).toBe(1000 - 200 - 8);
  });

  it("keeps the requested side unless asked to flip", () => {
    const anchor = rect(760, 400);

    expect(
      placeFloating(anchor, { width: 200, height: 300 }, "bottom").placement,
    ).toBe("bottom");
    expect(
      placeFloating(anchor, { width: 200, height: 300 }, "bottom", {
        flip: true,
      }).placement,
    ).toBe("top");
  });

  it("stays put when the other side has even less room", () => {
    const anchor = rect(390, 400);

    expect(
      placeFloating(anchor, { width: 200, height: 500 }, "bottom", {
        flip: true,
      }).placement,
    ).toBe("bottom");
  });
});
