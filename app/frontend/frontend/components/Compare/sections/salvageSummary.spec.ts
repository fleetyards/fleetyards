import { describe, expect, it } from "vitest";
import type { Hardpoint } from "@/services/fyApi";
import { salvageSummary } from "./salvageSummary";

const controller = (name: string, typeData: Record<string, unknown>) =>
  ({
    name,
    component: { typeData: { salvageController: true, ...typeData } },
    hardpoints: [],
  }) as unknown as Hardpoint;

describe("salvageSummary", () => {
  it("reads the Moth's cabs for its crates and its tool arm for the hull work", () => {
    const summary = salvageSummary([
      controller("cab_front", {
        heads: 1,
        crates: { maxSize: 1, fillTimePerScu: 3 },
        scrapingResource: "Recycled Material Composite",
      }),
      controller("cab_left", {
        heads: 1,
        crates: { maxSize: 8, fillTimePerScu: 3 },
      }),
      controller("cab_right", {
        heads: 1,
        crates: { maxSize: 8, fillTimePerScu: 3 },
      }),
      controller("tool_arm", {
        heads: 0,
        crates: { maxSize: 1, fillTimePerScu: 1 },
        disintegration: { maxRadius: 60.75, timePerMetre: 2.52 },
      }),
    ]);

    expect(summary?.heads).toBe(3);
    expect(summary?.crate).toEqual({ size: 8, fillTimePerScu: 3 });
    expect(summary?.structural?.disintegration?.maxRadius).toBe(60.75);
    expect(summary?.scrapingResource).toBe("Recycled Material Composite");
  });

  it("reads nothing for a tractor-only controller", () => {
    expect(salvageSummary([controller("c1", { heads: 1 })])).toBeUndefined();
  });

  it("reads nothing for a ship without a salvage controller", () => {
    expect(
      salvageSummary([
        { name: "gun", component: { typeData: {} } } as unknown as Hardpoint,
      ]),
    ).toBeUndefined();
  });
});
