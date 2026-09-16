import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { addMonths, addDays, formatISO } from "date-fns";
import Component from "./index.vue";

const isoDate = (date: Date) => formatISO(date, { representation: "date" });

describe("SupporterStatus", () => {
  it("says so when the account supports nothing", async () => {
    const wrapper = await mountWithDefaults(Component, { props: {} });

    expect(wrapper.text()).toContain("Not a supporter");
  });

  it("names the day support lapses", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        supporterUntil: isoDate(addMonths(new Date(), 3)),
      },
    });

    expect(wrapper.text()).toContain("Supporter");
    expect(wrapper.text()).toContain("Active until");
  });

  // An open-ended recurring pledge has no date to name, and "active until —"
  // would read as support that has already lapsed.
  it("says a pledge is ongoing when it carries no date", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { supporter: true },
    });

    expect(wrapper.text()).toContain("Recurring, no end date");
    expect(wrapper.text()).not.toContain("Active until");
  });

  it("switches wording and tone once the lapse is close", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        supporterUntil: isoDate(addDays(new Date(), 3)),
      },
    });

    expect(wrapper.text()).toContain("Expires");
    expect(
      wrapper.find("[data-test='supporter-status-pill']").classes(),
    ).toEqual(expect.arrayContaining([expect.stringContaining("warning")]));
  });

  // The fleet tier is for an admin to act on; the donor is told only that they
  // are a supporter.
  it("leaves the fleet tier out unless it is given", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { supporter: true },
    });

    expect(wrapper.find("[data-test='fleet-tier-until']").exists()).toBe(false);
    expect(wrapper.text()).not.toContain("Tier");
  });

  it("names the day the fleet tier would run out", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { supporter: true, fleetTierUntil: "2026-11-16" },
    });

    expect(wrapper.find("[data-test='fleet-tier-until']").text()).toContain(
      "Fleet tier until",
    );
  });

  // The fleet tier and supporterUntil answer different questions off the same
  // money, so showing both puts two dates side by side that disagree.
  it("drops the lapse date wherever the fleet tier is shown", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        supporterUntil: isoDate(addDays(new Date(), 20)),
        fleetTierUntil: "2026-11-16",
      },
    });

    expect(wrapper.text()).not.toContain("Active until");
    expect(wrapper.text()).not.toContain("Expires");
    expect(wrapper.text()).toContain("Fleet tier until");
  });

  // The hidden supporterUntil is days away and the fleet tier is months away, so
  // tinting for the former would warn about a date nobody can see.
  it("tints for the soonest date it actually shows", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        supporterUntil: isoDate(addDays(new Date(), 3)),
        fleetTierUntil: isoDate(addMonths(new Date(), 2)),
      },
    });

    expect(
      wrapper.find("[data-test='supporter-status-pill']").classes(),
    ).toEqual(expect.arrayContaining([expect.stringContaining("success")]));
  });

  // Nothing is sustained by nothing, so the fleet tier stays off a lapsed
  // account even when a date is handed in.
  it("drops the fleet tier when support is not live", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: false,
        fleetTierUntil: "2026-11-16",
      },
    });

    expect(wrapper.find("[data-test='fleet-tier-until']").exists()).toBe(false);
  });

  // A fixed date bought outright can simply be behind us -- an ended pledge
  // that paid for eight months ran out on a day that has been and gone.
  it("says so when the fleet tier has run out", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        fleetTierUntil: isoDate(addDays(new Date(), -7)),
      },
    });

    expect(wrapper.find("[data-test='fleet-tier-expired']").exists()).toBe(
      true,
    );
  });

  it("leaves the expired mark off a date still to come", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        fleetTierUntil: isoDate(addMonths(new Date(), 2)),
      },
    });

    expect(wrapper.find("[data-test='fleet-tier-until']").exists()).toBe(true);
    expect(wrapper.find("[data-test='fleet-tier-expired']").exists()).toBe(
      false,
    );
  });

  // A patron holds it while they are paying, so there is no date and nothing to
  // call expired.
  it("says the fleet tier stands while a pledge is paying", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { supporter: true, fleetTierOngoing: true },
    });

    expect(wrapper.find("[data-test='fleet-tier-ongoing']").exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='fleet-tier-expired']").exists()).toBe(
      false,
    );
  });

  // Ongoing wins: a date left over from an older donation would otherwise sit
  // beside a pledge that is still paying and read as the end of it.
  it("prefers the standing pledge over a leftover date", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        fleetTierOngoing: true,
        fleetTierUntil: isoDate(addDays(new Date(), -7)),
      },
    });

    expect(wrapper.find("[data-test='fleet-tier-ongoing']").exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='fleet-tier-until']").exists()).toBe(false);
  });

  // Nothing runs out while a pledge is paying, so the urgency tint has no date
  // to answer for -- a leftover one must not amber a badge that reads ongoing.
  it("does not warn while the pledge stands", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        fleetTierOngoing: true,
        fleetTierUntil: isoDate(addDays(new Date(), -7)),
        supporterUntil: isoDate(addDays(new Date(), 2)),
      },
    });

    expect(
      wrapper.find("[data-test='supporter-status-pill']").classes(),
    ).toEqual(expect.arrayContaining([expect.stringContaining("success")]));
  });
});
