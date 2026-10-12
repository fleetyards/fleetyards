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

  // Tier 0 is everybody below the first band, so there is nothing to pin on
  // them; the caller shows its own mark.
  it("renders nothing without a band", async () => {
    const wrapper = await mountWithDefaults(Component, { props: { tier: 0 } });

    expect(wrapper.find("[data-test='supporter-badge']").exists()).toBe(false);
  });

  it("names the band in words", async () => {
    const wrapper = await mountWithDefaults(Component, { props: { tier: 3 } });

    expect(wrapper.attributes("aria-label")).toBe("Tier 3");
  });

  // Every caller renders this beside a visible "Supporter", so repeating the
  // word here has it announced twice.
  it("keeps the word supporter out of its accessible name", async () => {
    const wrapper = await mountWithDefaults(Component, { props: { tier: 2 } });

    expect(wrapper.attributes("aria-label")).not.toContain("supporter");
    expect(wrapper.find("img").attributes("alt")).toBe("");
  });
});
