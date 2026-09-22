import { describe, expect, it } from "vitest";
import { missionTextParts, missionTextPlain } from "./index";

// The strings the game ships are templates, not finished sentences: 902 of the
// 2,472 titles and 2,344 of the 2,475 descriptions carry a substitution, and
// the localisation file uses `<EM4>` 3,567 times -- four of which never close.
describe("missionTextParts", () => {
  it("names the hole rather than filling or deleting it", () => {
    const parts = missionTextParts(
      "Head over to ~mission(Location|Address) and clear it out.",
    );

    expect(parts).toEqual([
      { kind: "text", value: "Head over to " },
      { kind: "token", value: "Location" },
      { kind: "text", value: " and clear it out." },
    ]);
  });

  // The part before the pipe is the noun worth showing; the rest names which
  // of its fields the game will substitute.
  it("takes the parameter's name, not the field it will read", () => {
    expect(missionTextParts("~mission(Contractor|OpenBountyTitle)")).toEqual([
      { kind: "token", value: "Contractor" },
    ]);
  });

  it("turns the game's own emphasis into emphasis", () => {
    expect(missionTextParts("Resupply <EM4>the depot</EM4> tonight.")).toEqual([
      { kind: "text", value: "Resupply " },
      { kind: "emphasis", value: "the depot" },
      { kind: "text", value: " tonight." },
    ]);
  });

  it("finds a substitution inside an emphasised run", () => {
    expect(
      missionTextParts("<EM4>resupply ~mission(Destination|Address)</EM4>"),
    ).toEqual([
      { kind: "emphasis", value: "resupply " },
      { kind: "token", value: "Destination" },
    ]);
  });

  // Four opens in the current build never close. Left alone, the tag itself
  // would be read out as part of the sentence.
  it("drops a tag that never closes rather than printing it", () => {
    expect(missionTextParts("Resupply <EM4>the depot tonight.")).toEqual([
      { kind: "text", value: "Resupply the depot tonight." },
    ]);
  });

  it("keeps several substitutions apart", () => {
    const parts = missionTextParts(
      "~mission(TargetName) was last seen at ~mission(Location).",
    );

    expect(parts.filter((part) => part.kind === "token")).toEqual([
      { kind: "token", value: "TargetName" },
      { kind: "token", value: "Location" },
    ]);
  });

  it("answers an absent string with nothing", () => {
    expect(missionTextParts(undefined)).toEqual([]);
    expect(missionTextParts(null)).toEqual([]);
    expect(missionTextParts("")).toEqual([]);
  });
});

// A meta title is plain text: `~mission(TargetName)` in a browser tab or a
// link preview reads as a bug rather than as the template it is.
describe("missionTextPlain", () => {
  it("brackets the substitution and takes the markup out", () => {
    expect(
      missionTextPlain("Bounty: <EM4>~mission(TargetName)</EM4> wanted"),
    ).toBe("Bounty: [TargetName] wanted");
  });
});
