import { describe, expect, it } from "vitest";
import { possessiveName, shownName } from "./possessiveName";

describe("possessiveName", () => {
  it("capitalises a username and adds the possessive", () => {
    expect(possessiveName({ username: "ghost" })).toBe("Ghost's");
  });

  it("adds nothing to a name ending in s, x or z", () => {
    expect(possessiveName({ username: "ghosts" })).toBe("Ghosts");
    expect(possessiveName({ username: "vex" })).toBe("Vex");
    expect(possessiveName({ username: "oz" })).toBe("Oz");
  });

  it("adds nothing to a name ending in an uppercase S, X or Z", () => {
    expect(possessiveName({ username: "ghost", displayName: "JAMES" })).toBe(
      "JAMES",
    );
  });

  it("uses the display name as written", () => {
    expect(
      possessiveName({ username: "ghost", displayName: "torlek maru" }),
    ).toBe("torlek maru's");
  });
});

describe("shownName", () => {
  it("prefers the display name over the username", () => {
    expect(shownName({ username: "ghost", displayName: "Torlek Maru" })).toBe(
      "Torlek Maru",
    );
    expect(shownName({ username: "ghost" })).toBe("Ghost");
  });
});
