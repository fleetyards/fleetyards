import { describe, it, expect, vi } from "vitest";
import type { Feature } from "@/services/fyAdminApi";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, options?: Record<string, unknown>) =>
      options ? `${key} ${JSON.stringify(options)}` : key,
  }),
}));

import { useFeatureState } from "./useFeatureState";

function feature(overrides: Partial<Feature> = {}): Feature {
  return {
    name: "fleet_logistics",
    state: "conditional",
    permanent: false,
    selfServiceUser: false,
    selfServiceFleet: false,
    percentageOfActors: 0,
    percentageOfTime: 0,
    groups: [],
    actors: [],
    fullyOnSince: null,
    lastChangedAt: null,
    lastChangedBy: null,
    lastChangedSource: null,
    ...overrides,
  };
}

describe("useFeatureState", () => {
  const { summaryParts, daysOpen } = useFeatureState();

  it("names one part per open gate", () => {
    const parts = summaryParts(
      feature({
        groups: ["testers"],
        percentageOfActors: 25,
        selfServiceUser: true,
        actors: [
          { type: "User", id: "1", name: "a", fid: null },
          { type: "User", id: "2", name: "b", fid: null },
          { type: "Fleet", id: "3", name: "c", fid: "C" },
        ],
      }),
    ).map((part) => part.key);

    expect(parts).toEqual([
      "group-testers",
      "percentage-of-actors",
      "users",
      "fleets",
      "self-service-user",
    ]);
  });

  // A flag on for everyone ignores its other gates, so listing them would
  // suggest they still narrow it.
  it("says everyone for a flag that is on", () => {
    const parts = summaryParts(
      feature({ state: "on", groups: ["testers"], percentageOfActors: 25 }),
    );

    expect(parts.map((part) => part.key)).toEqual(["everyone"]);
  });

  it("has nothing to say for a flag that is off", () => {
    expect(summaryParts(feature({ state: "off" }))).toEqual([]);
  });

  it("counts whole days open", () => {
    const twoDaysAgo = new Date(Date.now() - 2.5 * 86_400_000).toISOString();

    expect(daysOpen(feature({ fullyOnSince: twoDaysAgo }))).toBe(2);
  });

  it("does not count a permanent flag as open", () => {
    expect(
      daysOpen(
        feature({ permanent: true, fullyOnSince: "2024-01-01T00:00:00Z" }),
      ),
    ).toBeNull();
  });
});
