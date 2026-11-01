import { describe, expect, it } from "vitest";

import {
  formatInZone,
  isoToWallClock,
  organiserTimeHint,
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

describe("organiserTimeHint", () => {
  const iso = "2026-11-05T01:00:00.000Z";

  const endIso = "2026-11-05T03:00:00.000Z";

  it("names the organiser's time when the viewer's clock reads differently", () => {
    expect(
      organiserTimeHint(iso, null, "America/New_York", "Europe/Berlin"),
    ).toBe("Wed 20:00 New York (EST)");
  });

  it("names the organiser's start and end", () => {
    expect(
      organiserTimeHint(iso, endIso, "America/New_York", "Europe/Berlin"),
    ).toBe("Wed 20:00–22:00 New York (EST)");
  });

  it("keeps the weekday on an end that falls on another day", () => {
    expect(
      organiserTimeHint(
        iso,
        "2026-11-05T06:00:00.000Z",
        "America/New_York",
        "Europe/Berlin",
      ),
    ).toBe("Wed 20:00–Thu 01:00 New York (EST)");
  });

  it("is null when both clocks read the same", () => {
    expect(
      organiserTimeHint(iso, endIso, "America/New_York", "America/New_York"),
    ).toBeNull();
  });

  it("shows the hint when only the end differs across a DST change", () => {
    expect(
      organiserTimeHint(
        "2026-03-29T00:30:00.000Z",
        "2026-03-29T02:30:00.000Z",
        "Europe/London",
        "UTC",
      ),
    ).toBe("Sun 00:30 GMT–03:30 GMT+1 London");
  });

  it("names the offset in force on the event's date", () => {
    expect(
      organiserTimeHint(
        "2026-07-15T20:00:00.000Z",
        null,
        "Europe/London",
        "UTC",
      ),
    ).toBe("Wed 21:00 London (GMT+1)");
  });

  it("drops a repeated zone name for UTC", () => {
    expect(organiserTimeHint(iso, null, "UTC", "Europe/Berlin")).toBe(
      "Thu 01:00 UTC",
    );
  });

  it("falls back to the zone's name for one the form does not offer", () => {
    expect(organiserTimeHint(iso, null, "America/Toronto", "UTC")).toBe(
      "Wed 20:00 America/Toronto (EST)",
    );
  });
});
