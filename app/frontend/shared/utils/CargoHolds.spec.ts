import { describe, expect, it } from "vitest";
import {
  formatMaxContainer,
  hasLoadableLimit,
  loadableContainerSizes,
} from "./CargoHolds";

describe("CargoHolds", () => {
  it("offers only the crate sizes below what the grid takes", () => {
    expect(loadableContainerSizes({ maxContainerSizeScu: 8 })).toEqual([
      4, 2, 1,
    ]);
    expect(loadableContainerSizes(undefined)).toEqual([]);
  });

  it("shows a hand-set limit beside the grid's own", () => {
    const hold = { maxContainerSizeScu: 8, maxLoadableContainerSizeScu: 2 };

    expect(hasLoadableLimit(hold)).toBe(true);
    expect(formatMaxContainer(hold)).toBe("2 SCU (grid 8 SCU)");
  });

  // A load can shrink the grid under a curated limit, which then stops
  // applying -- the server serves the grid's own, so the admin has to as well.
  it("shows the grid's own where a limit no longer stays under it", () => {
    const hold = { maxContainerSizeScu: 2, maxLoadableContainerSizeScu: 4 };

    expect(hasLoadableLimit(hold)).toBe(false);
    expect(formatMaxContainer(hold)).toBe("2 SCU");
  });
});
