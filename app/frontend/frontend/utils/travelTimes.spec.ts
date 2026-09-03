import { describe, expect, it } from "vitest";
import { type Component } from "@/services/fyApi";
import { quantumDriveTravelTime } from "./travelTimes";

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
