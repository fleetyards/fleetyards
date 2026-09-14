import { describe, expect, it } from "vitest";
import { checkFeatures } from "./Access";

describe("checkFeatures", () => {
  it("passes a route that names no flag", () => {
    expect(checkFeatures(undefined, () => false)).toBe(true);
  });

  it("reads a single flag", () => {
    const isEnabled = (flag: string) => flag === "a";

    expect(checkFeatures("a", isEnabled)).toBe(true);
    expect(checkFeatures("b", isEnabled)).toBe(false);
  });

  // The point of the array form: a fleet's tours need the tours feature and
  // the fleet one, so either being off closes the route.
  it("wants every flag in a stack", () => {
    const enabled = ["a", "b"];
    const isEnabled = (flag: string) => enabled.includes(flag);

    expect(checkFeatures(["a", "b"], isEnabled)).toBe(true);
    expect(checkFeatures(["a", "c"], isEnabled)).toBe(false);
    expect(checkFeatures(["c", "a"], isEnabled)).toBe(false);
  });
});
