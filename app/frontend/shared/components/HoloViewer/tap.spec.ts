import { describe, expect, it } from "vitest";
import { tapActs } from "./tap";

describe("tapActs", () => {
  it("acts on a click at once", () => {
    expect(tapActs(false, "door", "rear", {})).toBe(true);
  });

  it("only points with a first tap", () => {
    expect(tapActs(true, "door", "rear", {})).toBe(false);
  });

  it("acts on a second tap on what is pointed", () => {
    expect(tapActs(true, "door", "rear", { door: "rear" })).toBe(true);
  });

  it("only points with a tap on something else", () => {
    expect(tapActs(true, "door", "rear", { door: "front" })).toBe(false);
    expect(tapActs(true, "builtIn", "rear", { door: "rear" })).toBe(false);
  });
});
