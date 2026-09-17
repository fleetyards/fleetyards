import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { SupporterContributionSourceEnum } from "@/services/fyAdminApi";
import Component from "./index.vue";

describe("SupporterContributionsSourcePill", () => {
  it("names the platform the money arrived on", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { source: SupporterContributionSourceEnum.BUYMEACOFFEE },
    });

    expect(wrapper.find("[data-test='source-pill']").text()).toContain(
      "Buy me a coffee",
    );
  });

  // Every persisted row has a source, so a missing one is a payload that has
  // not loaded rather than a contribution from nowhere.
  it("falls back to a dash when no source is given", async () => {
    const wrapper = await mountWithDefaults(Component, { props: {} });

    expect(wrapper.find("[data-test='source-pill']").exists()).toBe(false);
    expect(wrapper.text()).toContain("—");
  });

  it("gives every platform its own icon", async () => {
    const icons = await Promise.all(
      Object.values(SupporterContributionSourceEnum).map(async (source) => {
        const wrapper = await mountWithDefaults(Component, {
          props: { source },
        });

        return wrapper.find("[data-test='source-pill'] i").classes().join();
      }),
    );

    expect(new Set(icons).size).toBe(icons.length);
  });
});
