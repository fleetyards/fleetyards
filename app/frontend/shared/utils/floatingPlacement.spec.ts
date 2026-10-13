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
  it("moves a tour card below a title when clamping its left placement would cover it", () => {
    const anchor = rect(180, 24, 280, 30);
    const position = placeFloating(
      anchor,
      { width: 360, height: 240 },
      "left",
      { gap: 12, margin: 12, avoidOverlap: true, flip: true },
    );

    expect(position.top).toBeGreaterThanOrEqual(anchor.bottom + 12);
  });

  it("keeps a narrow-screen tour card above a bottom-edge add button", () => {
    Object.assign(window, { innerWidth: 390, innerHeight: 844 });
    const anchor = rect(710, 310, 59, 59);
    const position = placeFloating(anchor, { width: 360, height: 240 }, "top", {
      gap: 12,
      margin: 12,
      avoidOverlap: true,
      flip: true,
    });

    expect(position.top + 240).toBeLessThanOrEqual(anchor.top - 12);
    expect(position.left).toBeGreaterThanOrEqual(12);
    expect(position.left + 360).toBeLessThanOrEqual(390 - 12);
  });

  it("keeps an overlap-avoiding box to the allowed sides", () => {
    Object.assign(window, { innerWidth: 400, innerHeight: 600 });
    const anchor = rect(100, 150, 100, 400);
    const position = placeFloating(
      anchor,
      { width: 140, height: 240 },
      "bottom",
      {
        gap: 12,
        margin: 12,
        avoidOverlap: true,
        sides: ["bottom", "top"],
      },
    );

    expect(["bottom", "top"]).toContain(position.placement);
  });

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
