import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("SupporterBadge", () => {
  it("gives every band its own insignia", async () => {
    const sources = await Promise.all(
      [1, 2, 3].map(async (tier) => {
        const wrapper = await mountWithDefaults(Component, { props: { tier } });

        return wrapper.find("img").attributes("src");
      }),
    );

    expect(new Set(sources).size).toBe(3);
  });

  // Tier 0 is everybody who gave nothing this month, so there is nothing to
  // pin on them.
  it("renders nothing without a band", async () => {
    const wrapper = await mountWithDefaults(Component, { props: { tier: 0 } });

    expect(wrapper.find("[data-test='supporter-badge']").exists()).toBe(false);
  });

  // The pairing: the insignia carries the band, a separate mark carries the
  // commitment. The three are raster art whose colour ramp is already spent on
  // the band, so there is nothing left to restyle.
  it("marks a standing pledge beside the insignia", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { tier: 2, recurring: true },
    });

    expect(
      wrapper.find("[data-test='supporter-badge-recurring']").exists(),
    ).toBe(true);
  });

  it("leaves the mark off a one-off", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { tier: 2, recurring: false },
    });

    expect(
      wrapper.find("[data-test='supporter-badge-recurring']").exists(),
    ).toBe(false);
  });

  // The same insignia means two different things depending on the mark, so the
  // text alternative has to say which.
  it("says in words whether the pledge stands", async () => {
    const once = await mountWithDefaults(Component, { props: { tier: 3 } });
    const standing = await mountWithDefaults(Component, {
      props: { tier: 3, recurring: true },
    });

    expect(once.find("img").attributes("alt")).toBe("Tier 3 supporter");
    expect(standing.find("img").attributes("alt")).toBe(
      "Tier 3 supporter, recurring",
    );
  });
});
