import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { Raffle } from "@/services/fyApi";
import Component from "./index.vue";

const raffle: Raffle = {
  id: "8d0e3c7a-0000-4000-8000-000000000003",
  title: "Win a Polaris",
  images: [],
  startsAt: "2026-11-01T18:00:00.000Z",
  runDays: 7,
  endsAt: "2026-11-08T18:00:00.000Z",
  claimPeriodDays: 21,
  status: "open",
  entriesCount: 3,
  forfeitedWinners: [],
  conditionsVersion: "2026-10-27",
  entered: false,
  won: false,
  claimable: false,
  claimed: false,
};

describe("RaffleConditions", () => {
  it("names the raffle's claim period and the conditions version", async () => {
    const wrapper = await mountWithDefaults(Component, { props: { raffle } });

    const text = wrapper.text();
    expect(text).toContain("21");
    expect(text).toContain("2026-10-27");
  });
});
