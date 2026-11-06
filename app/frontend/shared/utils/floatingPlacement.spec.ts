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

  describe("sideways", () => {
    const tall = { width: 200, height: 500 };
    const options = { flip: true, sideways: true };

    it("stays below or above while the box fits there", () => {
      expect(
        placeFloating(rect(100, 400), tall, "bottom", options).placement,
      ).toBe("bottom");
      expect(
        placeFloating(rect(700, 400), tall, "bottom", options).placement,
      ).toBe("top");
    });

    it("goes beside the anchor, clear of it, when neither side has room", () => {
      const anchor = rect(390, 400);
      const { placement, left, top } = placeFloating(
        anchor,
        tall,
        "bottom",
        options,
      );

      expect(placement).toBe("right");
      expect(left).toBeGreaterThanOrEqual(anchor.right);
      expect(top).toBeGreaterThanOrEqual(0);
      expect(top + tall.height).toBeLessThanOrEqual(800);
    });

    it("runs down from the anchor, sliding up only to stay inside", () => {
      const roomy = { width: 200, height: 500 };

      expect(
        placeFloating(rect(390, 400), roomy, "bottom", {
          ...options,
          margin: 8,
        }).top,
      ).toBe(800 - 500 - 8);

      Object.assign(window, { innerHeight: 1000 });

      expect(placeFloating(rect(480, 400), roomy, "bottom", options).top).toBe(
        480,
      );
    });

    it("leaves a box asked to sit beside its anchor centred on it", () => {
      expect(
        placeFloating(rect(390, 400), { width: 100, height: 100 }, "right", {
          sideways: true,
        }).top,
      ).toBe(350);
    });

    it("takes the left when the right has no room", () => {
      const anchor = rect(390, 850);
      const { placement, left } = placeFloating(
        anchor,
        tall,
        "bottom",
        options,
      );

      expect(placement).toBe("left");
      expect(left + tall.width).toBeLessThanOrEqual(anchor.left);
    });

    it("falls back to sliding inside when no side has room", () => {
      Object.assign(window, { innerWidth: 300 });

      expect(
        placeFloating(rect(390, 100), tall, "bottom", options).placement,
      ).toBe("bottom");
    });
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
