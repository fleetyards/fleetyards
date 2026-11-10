import { describe, expect, it } from "vitest";
import { clearFrame } from "./frameInsets";

describe("clearFrame", () => {
  it("is the whole frame without insets", () => {
    expect(clearFrame(1000, 600)).toEqual({
      width: 1000,
      height: 600,
      offsetX: 0,
      offsetY: 0,
    });
  });

  it("shifts the view onto the part a panel and a card leave clear", () => {
    expect(
      clearFrame(1000, 600, { top: 200, right: 0, bottom: 0, left: 400 }),
    ).toEqual({ width: 600, height: 400, offsetX: -200, offsetY: -100 });
  });

  it("takes the whole frame when too little of it is clear", () => {
    expect(
      clearFrame(1000, 600, { top: 0, right: 0, bottom: 0, left: 900 }),
    ).toEqual({ width: 1000, height: 600, offsetX: 0, offsetY: 0 });
  });
});
