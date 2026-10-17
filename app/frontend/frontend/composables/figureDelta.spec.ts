import { describe, expect, it } from "vitest";
import { figureDelta } from "./figureDelta";

const whole = (value: number) => String(Math.round(value));
const precise = (value: number) => String(Math.round(value * 100) / 100);

describe("figureDelta", () => {
  it("labels a move as a percentage of where it was", () => {
    expect(figureDelta(100, 150, false, whole)).toEqual({
      deltaLabel: "+50%",
      tone: "better",
    });
    expect(figureDelta(100, 150, true, whole).tone).toBe("worse");
  });

  it("shows no move that rounds away", () => {
    expect(figureDelta(1000, 1002, false, whole)).toEqual({});
    expect(figureDelta(0, 0.3, false, whole)).toEqual({});
  });

  it("labels a move from nothing as the difference, in the caller's format", () => {
    expect(figureDelta(0, 0.3, false, precise)).toEqual({
      deltaLabel: "+0.3",
      tone: "better",
    });
  });
});
