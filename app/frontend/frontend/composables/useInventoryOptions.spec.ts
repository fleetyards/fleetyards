import { describe, expect, it } from "vitest";
import { unitsForCategory } from "./useInventoryOptions";

describe("unitsForCategory", () => {
  it("measures bulk cargo in SCU and gear per piece", () => {
    expect(unitsForCategory("commodity")).toEqual(["scu"]);
    expect(unitsForCategory("component")).toEqual(["units"]);
    expect(unitsForCategory("other")).toEqual(["scu", "units"]);
  });

  // The game hands the gems out a piece at a time and a crafting recipe asks
  // for a number of them, so an inventory has to be able to say the same.
  it("offers pieces for a counted commodity", () => {
    expect(unitsForCategory("commodity", true)).toEqual(["scu", "units"]);
  });

  // Widened, not flipped: the gems are still sold by the crate, and every
  // commodity position ever recorded is in SCU.
  it("keeps SCU on offer for a counted commodity", () => {
    expect(unitsForCategory("commodity", true)).toContain("scu");
  });

  // A free-text position points at no catalogue row, so nothing says it is
  // counted and the SCU-only rule stands -- the same answer the API gives.
  it("leaves a commodity that is not counted alone", () => {
    expect(unitsForCategory("commodity", undefined)).toEqual(["scu"]);
    expect(unitsForCategory("commodity", false)).toEqual(["scu"]);
  });

  // Gear is already per piece, so being counted adds nothing and must not
  // duplicate the entry.
  it("does not repeat a unit the category already offers", () => {
    expect(unitsForCategory("component", true)).toEqual(["units"]);
  });

  it("offers both for a category nothing has a habit for", () => {
    expect(unitsForCategory(undefined)).toEqual(["scu", "units"]);
  });
});
