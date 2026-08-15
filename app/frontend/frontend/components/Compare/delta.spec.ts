import { describe, expect, it } from "vitest";
import { deltasAgainst } from "./delta";

describe("deltasAgainst", () => {
  it("measures every cell against the baseline", () => {
    expect(deltasAgainst([100, 150, 50], 0, "higher")).toEqual([
      { percent: 0, tone: "even" },
      { percent: 50, tone: "better" },
      { percent: -50, tone: "worse" },
    ]);
  });

  it("inverts for metrics where less is better", () => {
    expect(deltasAgainst([100, 150, 50], 0, "lower")).toEqual([
      { percent: 0, tone: "even" },
      { percent: 50, tone: "worse" },
      { percent: -50, tone: "better" },
    ]);
  });

  it("claims neither side without a direction", () => {
    expect(deltasAgainst([100, 150], 0)).toEqual([
      { percent: 0, tone: "even" },
      { percent: 50, tone: "even" },
    ]);
  });

  it("calls a difference the label would round away even", () => {
    expect(deltasAgainst([1000, 1002], 0, "higher")[1]).toEqual({
      percent: 0.2,
      tone: "even",
    });
  });

  it("skips cells with no comparable value", () => {
    expect(deltasAgainst([100, undefined, NaN], 0, "higher")).toEqual([
      { percent: 0, tone: "even" },
      undefined,
      undefined,
    ]);
  });

  // The table reads an all-undefined row as "baseline mode does not apply here" and keeps
  // showing the values, so textual rows must not produce deltas.
  it("yields nothing for a row the baseline cannot anchor", () => {
    expect(deltasAgainst([undefined, undefined], 0, "higher")).toEqual([
      undefined,
      undefined,
    ]);

    expect(deltasAgainst([0, 50], 0, "higher")).toEqual([undefined, undefined]);

    expect(deltasAgainst([100, 150], -1, "higher")).toEqual([
      undefined,
      undefined,
    ]);
  });

  it("measures against a negative baseline by its magnitude", () => {
    expect(deltasAgainst([-100, -50], 0, "higher")[1]).toEqual({
      percent: 50,
      tone: "better",
    });
  });
});
