import { describe, expect, it } from "vitest";
import { type Component } from "@/services/fyApi";
import { quantumDriveImage, quantumDriveTravelTime } from "./travelTimes";

// Only the fields the calculation reads, in the units the sc_data parser
// writes them: metres and metres per second.
const drive = (typeData: Record<string, number> | undefined) =>
  ({ typeData }) as unknown as Component;

const beacon = drive({
  driveSpeed: 283046000,
  stageOneAccelRate: 49500000,
  stageTwoAccelRate: 1500000,
});

const expedition = drive({
  driveSpeed: 183046000,
  stageOneAccelRate: 39500000,
  stageTwoAccelRate: 1200000,
});

describe("quantumDriveTravelTime", () => {
  it("reads the distance as millions of kilometres", () => {
    expect(quantumDriveTravelTime(beacon, 20)).toBeCloseTo(78.277, 2);
    expect(quantumDriveTravelTime(expedition, 20)).toBeCloseTo(115.436, 2);
  });

  it("takes longer over a longer distance", () => {
    expect(quantumDriveTravelTime(beacon, 50)!).toBeGreaterThan(
      quantumDriveTravelTime(beacon, 20)!,
    );
  });

  // The unit the distance arrives in decided the ordering: fed kilometres
  // instead of millions of them, the formula returned negative times and
  // ranked the slower drive first.
  it("ranks the faster drive below the slower one", () => {
    expect(quantumDriveTravelTime(beacon, 20)!).toBeGreaterThan(0);
    expect(quantumDriveTravelTime(beacon, 20)!).toBeLessThan(
      quantumDriveTravelTime(expedition, 20)!,
    );
  });

  it("has no answer for a drive the export never described", () => {
    expect(quantumDriveTravelTime(drive(undefined), 20)).toBeUndefined();
    expect(quantumDriveTravelTime(drive({ jumpRange: 1 }), 20)).toBeUndefined();
  });
});

describe("quantumDriveImage", () => {
  const withMedia = (media: Record<string, unknown>) =>
    ({ media }) as unknown as Component;

  it("pictures a drive by its angled view", () => {
    expect(
      quantumDriveImage(
        withMedia({
          angledView: { smallUrl: "angled-small.png", url: "angled.png" },
          storeImage: { smallUrl: "store-small.png", url: "store.png" },
        }),
      ),
    ).toBe("angled-small.png");
  });

  it("falls back to the store image without an angled view", () => {
    expect(
      quantumDriveImage(
        withMedia({ storeImage: { smallUrl: "store-small.png" } }),
      ),
    ).toBe("store-small.png");
  });

  // A vector is served with `smallUrl` set to the file itself, so only a
  // non-representable raster arrives with `url` alone.
  it("uses the original file when it has no representations", () => {
    expect(
      quantumDriveImage(withMedia({ angledView: { url: "angled.png" } })),
    ).toBe("angled.png");
  });

  it("has no picture for a drive with neither", () => {
    expect(quantumDriveImage(withMedia({}))).toBeUndefined();
  });
});
