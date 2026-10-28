import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { Raffle } from "@/services/fyApi";
import Component from "./index.vue";

const raffle: Raffle = {
  id: "8d0e3c7a-0000-4000-8000-000000000004",
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

describe("RaffleEntryPanel", () => {
  it.each(["closed", "drawn", "concluded"] as const)(
    "says a %s raffle is over",
    async (status) => {
      const wrapper = await mountWithDefaults(Component, {
        props: { raffle: { ...raffle, status } },
      });

      expect(wrapper.find('[data-test="raffle-over"]').exists()).toBe(true);
    },
  );

  it("leaves the notice off an open raffle", async () => {
    const wrapper = await mountWithDefaults(Component, { props: { raffle } });

    expect(wrapper.find('[data-test="raffle-over"]').exists()).toBe(false);
  });

  it("leaves the notice off for the winner", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        raffle: { ...raffle, status: "drawn", won: true, claimed: true },
      },
    });

    expect(wrapper.find('[data-test="raffle-over"]').exists()).toBe(false);
  });
});
