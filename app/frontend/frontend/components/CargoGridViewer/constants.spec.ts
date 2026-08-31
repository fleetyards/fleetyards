import { describe, expect, it } from "vitest";
import {
  containersForVolume,
  encodeContainerCounts,
  parseContainerCounts,
} from "./constants";

describe("containersForVolume", () => {
  it("carries a volume in the fewest crates", () => {
    expect(containersForVolume(12)).toEqual({ 8: 1, 4: 1 });
    expect(containersForVolume(70)).toEqual({ 32: 2, 4: 1, 2: 1 });
  });

  it("repeats the largest crate rather than stopping at one", () => {
    expect(containersForVolume(96)).toEqual({ 32: 3 });
  });

  it("drops what is too little to fill the smallest crate", () => {
    expect(containersForVolume(4.6)).toEqual({ 4: 1 });
    expect(containersForVolume(0.4)).toEqual({});
  });
});

describe("container counts in a URL", () => {
  it("round-trips a load", () => {
    const counts = containersForVolume(37);

    expect(encodeContainerCounts(counts)).toBe("32x1,4x1,1x1");
    expect(parseContainerCounts(encodeContainerCounts(counts))).toEqual(counts);
  });

  it("leaves out the sizes nothing was asked for", () => {
    expect(encodeContainerCounts({ 32: 0, 8: 2 })).toBe("8x2");
  });

  // The query is as editable as the page's own inputs, so it is read rather
  // than trusted: a size the viewer cannot draw would only pack into nothing.
  it("keeps only the crates the viewer draws", () => {
    expect(parseContainerCounts("32x2,7x3,16xmany,8x0,4x-1,nonsense")).toEqual({
      32: 2,
    });
  });

  it("has nothing to read without a query", () => {
    expect(parseContainerCounts(undefined)).toEqual({});
    expect(parseContainerCounts(["32x1"])).toEqual({});
  });
});
