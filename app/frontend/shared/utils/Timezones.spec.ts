import { describe, expect, it } from "vitest";

import {
  formatInZone,
  isoToWallClock,
  resolveTimezone,
  wallClockToIso,
} from "./Timezones";

describe("resolveTimezone", () => {
  it("keeps a zone the browser knows", () => {
    expect(resolveTimezone("America/New_York")).toBe("America/New_York");
  });

  it("falls back to UTC for a missing or unknown zone", () => {
    expect(resolveTimezone(undefined)).toBe("UTC");
    expect(resolveTimezone("")).toBe("UTC");
    expect(resolveTimezone("Mars/Olympus_Mons")).toBe("UTC");
  });
});

describe("wallClockToIso", () => {
  it("reads the wall clock in the given zone, not the browser's", () => {
    expect(wallClockToIso("2026-11-04T20:00", "America/New_York")).toBe(
      "2026-11-05T01:00:00.000Z",
    );
    expect(wallClockToIso("2026-11-04T20:00", "Europe/Berlin")).toBe(
      "2026-11-04T19:00:00.000Z",
    );
  });

  it("uses the offset in force on that date", () => {
    // New York is still on daylight time on 31 October 2026.
    expect(wallClockToIso("2026-10-31T20:00", "America/New_York")).toBe(
      "2026-11-01T00:00:00.000Z",
    );
  });

  it("returns null for an empty or unreadable value", () => {
    expect(wallClockToIso("", "UTC")).toBeNull();
    expect(wallClockToIso(null, "UTC")).toBeNull();
    expect(wallClockToIso("not a date", "UTC")).toBeNull();
  });
});

describe("isoToWallClock", () => {
  it("shows the instant as the wall clock in the given zone", () => {
    expect(isoToWallClock("2026-11-05T01:00:00.000Z", "America/New_York")).toBe(
      "2026-11-04T20:00",
    );
  });

  it("round-trips with wallClockToIso", () => {
    const iso = wallClockToIso("2026-03-29T02:30", "Asia/Tokyo");
    expect(isoToWallClock(iso, "Asia/Tokyo")).toBe("2026-03-29T02:30");
  });

  it("returns an empty string for a missing value", () => {
    expect(isoToWallClock(null, "UTC")).toBe("");
  });
});

describe("formatInZone", () => {
  it("formats the instant in the given zone", () => {
    expect(
      formatInZone("2026-11-05T01:00:00.000Z", "America/New_York", "HH:mm"),
    ).toBe("20:00");
  });
});
