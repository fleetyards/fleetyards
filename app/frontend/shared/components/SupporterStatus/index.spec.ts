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
        supporterTier: 1,
        supporterUntil: isoDate(addMonths(new Date(), 3)),
      },
    });

    expect(wrapper.text()).toContain("Supporter");
    expect(wrapper.text()).toContain("Tier 1");
    expect(wrapper.text()).toContain("Active until");
  });

  // An open-ended recurring pledge has no date to name, and "active until —"
  // would read as support that has already lapsed.
  it("says a pledge is ongoing when it carries no date", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { supporter: true, supporterTier: 2 },
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

  // Tier 0 is what every non-supporter has, so it carries no information.
  it("leaves a zero tier off", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { supporter: true, supporterTier: 0 },
    });

    expect(wrapper.text()).not.toContain("Tier");
  });
});
