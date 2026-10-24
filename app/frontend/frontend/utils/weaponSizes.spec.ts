import { describe, expect, it } from "vitest";
import { formatWeaponSizes } from "./weaponSizes";

describe("formatWeaponSizes", () => {
  it("lists the guns by size, largest first", () => {
    expect(
      formatWeaponSizes([
        { size: 2, count: 4 },
        { size: 3, count: 2 },
      ]),
    ).toBe("2×S3 · 4×S2");
  });

  it("is empty for a ship without guns", () => {
    expect(formatWeaponSizes([])).toBe("");
    expect(formatWeaponSizes(undefined)).toBe("");
  });
});
