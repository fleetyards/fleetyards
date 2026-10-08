import { describe, expect, it } from "vitest";
import { possessiveUsername } from "./possessiveUsername";

describe("possessiveUsername", () => {
  it("capitalises and adds the possessive", () => {
    expect(possessiveUsername("ghost")).toBe("Ghost's");
  });

  it("adds nothing to a name ending in s, x or z", () => {
    expect(possessiveUsername("ghosts")).toBe("Ghosts");
    expect(possessiveUsername("vex")).toBe("Vex");
    expect(possessiveUsername("oz")).toBe("Oz");
  });
});
