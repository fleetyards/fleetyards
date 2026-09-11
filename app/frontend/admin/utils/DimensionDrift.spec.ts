import { describe, expect, it } from "vitest";
import { hasDrifted, isAppliable, isPresent } from "./DimensionDrift";

describe("isPresent", () => {
  it("counts zero and empty string as present", () => {
    expect(isPresent(0)).toBe(true);
    expect(isPresent("")).toBe(true);
  });

  it("counts null and undefined as absent", () => {
    expect(isPresent(null)).toBe(false);
    expect(isPresent(undefined)).toBe(false);
  });
});

describe("hasDrifted", () => {
  it("is false when the two agree", () => {
    expect(hasDrifted(10, 10)).toBe(false);
  });

  it("is false when the field is a string of the same number", () => {
    expect(hasDrifted("10", 10)).toBe(false);
    expect(hasDrifted("10.00", 10)).toBe(false);
  });

  it("is true when they differ", () => {
    expect(hasDrifted(10, 12)).toBe(true);
  });

  // The backend scope selects these, so the page has to show something.
  it("is true when the game files gave no value", () => {
    expect(hasDrifted(10, null)).toBe(true);
    expect(hasDrifted(10, undefined)).toBe(true);
  });

  it("is false when neither side has a value", () => {
    expect(hasDrifted(null, null)).toBe(false);
    expect(hasDrifted(undefined, undefined)).toBe(false);
  });
});

describe("isAppliable", () => {
  it("is true when there is a differing value to take over", () => {
    expect(isAppliable(10, 12)).toBe(true);
  });

  it("is false when they already agree", () => {
    expect(isAppliable(10, 10)).toBe(false);
  });

  // Drifted, but there is nothing to copy -- so no button.
  it("is false when the game files gave no value", () => {
    expect(isAppliable(10, null)).toBe(false);
    expect(hasDrifted(10, null)).toBe(true);
  });
});
