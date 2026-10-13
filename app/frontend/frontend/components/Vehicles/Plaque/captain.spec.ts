import { describe, expect, it } from "vitest";
import { ownerCaptain, publicOwnerCaptain } from "./captain";

describe("ownerCaptain", () => {
  it("names the owner by their display name, else their username", () => {
    expect(
      ownerCaptain({
        username: "torlek",
        displayName: "Torlek Maru",
        hideOwner: false,
      }),
    ).toBe("Torlek Maru");
    expect(ownerCaptain({ username: "torlek", hideOwner: false })).toBe(
      "torlek",
    );
  });

  it("names nobody for an owner who hides themselves", () => {
    expect(
      ownerCaptain({
        username: "torlek",
        displayName: "Torlek Maru",
        hideOwner: true,
      }),
    ).toBeUndefined();
    expect(ownerCaptain(undefined)).toBeUndefined();
  });
});

describe("publicOwnerCaptain", () => {
  it("names the owner the public payload carries", () => {
    expect(
      publicOwnerCaptain({
        username: "torlek",
        userDisplayName: "Torlek Maru",
      }),
    ).toBe("Torlek Maru");
    expect(publicOwnerCaptain({ username: "torlek" })).toBe("torlek");
    expect(publicOwnerCaptain({})).toBeUndefined();
  });
});
