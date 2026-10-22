import { describe, expect, it } from "vitest";
import { fociText } from "./Foci";

describe("fociText", () => {
  it("joins the labels, with stealth last", () => {
    expect(
      fociText({ fociLabels: ["Medium Fighter"], stealth: true }, "Stealth"),
    ).toBe("Medium Fighter, Stealth");
  });

  it("says nothing when there is nothing to say", () => {
    expect(fociText({ fociLabels: [], stealth: false }, "Stealth")).toBe(
      undefined,
    );
  });
});
