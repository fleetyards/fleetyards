import { describe, expect, it } from "vitest";
import { parseLocalizedNumber } from "@/shared/utils/parseLocalizedNumber";

describe("parseLocalizedNumber", () => {
  it("reads German grouping and decimals", () => {
    expect(parseLocalizedNumber("1.500.000", "de")).toBe("1500000");
    expect(parseLocalizedNumber("1.500,50", "de")).toBe("1500.50");
    expect(parseLocalizedNumber("1500,5", "de")).toBe("1500.5");
    expect(parseLocalizedNumber("1.500", "de")).toBe("1500");
  });

  it("reads English grouping and decimals", () => {
    expect(parseLocalizedNumber("1,500,000", "en")).toBe("1500000");
    expect(parseLocalizedNumber("1,500.50", "en")).toBe("1500.50");
    expect(parseLocalizedNumber("1,500", "en")).toBe("1500");
    expect(parseLocalizedNumber("1500.5", "en")).toBe("1500.5");
  });

  // A dot followed by anything but three digits can only be a decimal, so a
  // German reader typing the English way is still understood.
  it("takes a lone foreign separator as a decimal when it cannot be grouping", () => {
    expect(parseLocalizedNumber("1500.5", "de")).toBe("1500.5");
    expect(parseLocalizedNumber("0,25", "en")).toBe("0.25");
  });

  it("ignores spaces used as grouping", () => {
    expect(parseLocalizedNumber("1 500,50", "fr")).toBe("1500.50");
  });

  it("answers null for anything that is not a number", () => {
    expect(parseLocalizedNumber("", "de")).toBeNull();
    expect(parseLocalizedNumber("abc", "de")).toBeNull();
    expect(parseLocalizedNumber("1,2,3.4.5", "de")).toBeNull();
    expect(parseLocalizedNumber(undefined, "de")).toBeNull();
  });

  it("keeps a negative sign", () => {
    expect(parseLocalizedNumber("-12,5", "de")).toBe("-12.5");
  });

  it("refuses grouping that is not in threes", () => {
    expect(parseLocalizedNumber("12,34,567", "en")).toBeNull();
    expect(parseLocalizedNumber("1.50.000", "de")).toBeNull();
    expect(parseLocalizedNumber("12,34,567.5", "en")).toBeNull();
    expect(parseLocalizedNumber("1.2345,5", "de")).toBeNull();
  });

  // Too many digits in front for a group, so it can only be a decimal.
  it("reads a long number with a foreign separator as a decimal", () => {
    expect(parseLocalizedNumber("1500.000", "de")).toBe("1500.000");
  });
});
