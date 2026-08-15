import { describe, expect, it } from "vitest";
import { markExtremes } from "./highlights";

describe("markExtremes", () => {
  it("marks the highest value best and the lowest worst", () => {
    expect(markExtremes([100, 300, 200], "higher")).toEqual([
      "worst",
      "best",
      undefined,
    ]);
  });

  it("inverts for metrics where less is better", () => {
    expect(markExtremes([100, 300, 200], "lower")).toEqual([
      "best",
      "worst",
      undefined,
    ]);
  });

  it("marks nothing without a direction", () => {
    expect(markExtremes([100, 300, 200])).toEqual([
      undefined,
      undefined,
      undefined,
    ]);
  });

  it("marks nothing when every value ties", () => {
    expect(markExtremes([200, 200, 200], "higher")).toEqual([
      undefined,
      undefined,
      undefined,
    ]);
  });

  it("marks every value tied at an extreme", () => {
    expect(markExtremes([300, 300, 100, 100], "higher")).toEqual([
      "best",
      "best",
      "worst",
      "worst",
    ]);
  });

  it("skips missing values and needs two comparable ones", () => {
    expect(markExtremes([undefined, 300, undefined], "higher")).toEqual([
      undefined,
      undefined,
      undefined,
    ]);

    expect(markExtremes([undefined, 300, 100], "higher")).toEqual([
      undefined,
      "best",
      "worst",
    ]);
  });

  it("ignores non-finite values", () => {
    expect(markExtremes([NaN, 300, 100], "higher")).toEqual([
      undefined,
      "best",
      "worst",
    ]);
  });

  it("handles two models", () => {
    expect(markExtremes([100, 200], "higher")).toEqual(["worst", "best"]);
  });
});
