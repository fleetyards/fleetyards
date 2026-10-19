import { describe, expect, it } from "vitest";
import { craftedLineLabel } from "./craftedLabel";

const t = (key: string, options?: Record<string, unknown>) =>
  options ? `${key} ${JSON.stringify(options)}` : key;

const crafted = (qualities: Record<string, number>) => ({
  blueprint: { id: "bp-1", name: "Bulwark", slug: "bulwark" },
  qualities,
});

describe("craftedLineLabel", () => {
  it("says any grade where the line names none", () => {
    expect(craftedLineLabel(t, crafted({}))).toBe(
      "labels.fleets.contracts.craftedAny",
    );
  });

  it("reads the grades by the line's rule", () => {
    expect(craftedLineLabel(t, crafted({ 1: 700 }), "exact")).toContain(
      "labels.fleets.contracts.craftedExact",
    );
    expect(craftedLineLabel(t, crafted({ 1: 700 }), "at_least")).toContain(
      "labels.fleets.contracts.craftedAtLeast",
    );
  });
});
