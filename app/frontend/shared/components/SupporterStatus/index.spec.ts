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

  // The projection is for an admin to act on. A supporter is told they are one;
  // which tier they end up holding is theirs to choose.
  it("leaves the tier projection out unless it is given", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { supporter: true },
    });

    expect(
      wrapper.find("[data-test='supporter-tier-projection']").exists(),
    ).toBe(false);
    expect(wrapper.text()).not.toContain("Tier");
  });

  it("names the day each tier would stop being sustained", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: true,
        supporterUntil: isoDate(addDays(new Date(), 20)),
        tierProjections: [
          { tier: 1, expiresAt: "2027-07-16" },
          { tier: 2, expiresAt: "2026-11-16" },
        ],
      },
    });

    const rows = wrapper.findAll("[data-test='supporter-tier-projection']");

    expect(rows).toHaveLength(2);
    expect(rows[0].text()).toContain("Tier 1 until");
    expect(rows[1].text()).toContain("Tier 2 until");
  });

  // Nothing is sustained by nothing, so the projection stays off a lapsed
  // account even when one is handed in.
  it("drops the projection when support is not live", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        supporter: false,
        tierProjections: [{ tier: 2, expiresAt: "2026-11-16" }],
      },
    });

    expect(
      wrapper.find("[data-test='supporter-tier-projection']").exists(),
    ).toBe(false);
  });
});
