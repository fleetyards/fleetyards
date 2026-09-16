import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { SupporterContributionLinkedViaEnum } from "@/services/fyAdminApi";
import Component from "./index.vue";

describe("SupporterContributionsLinkedViaPill", () => {
  it("names the rule that produced the link", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { linkedVia: SupporterContributionLinkedViaEnum.CLAIM_KEY },
    });

    expect(wrapper.find("[data-test='linked-via-pill']").text()).toContain(
      "Supporter token",
    );
  });

  // An unlinked contribution has no rule to name, and an empty cell would read
  // as a missing value rather than as an answer.
  it("falls back to a dash when nothing is linked", async () => {
    const wrapper = await mountWithDefaults(Component, { props: {} });

    expect(wrapper.find("[data-test='linked-via-pill']").exists()).toBe(false);
    expect(wrapper.text()).toContain("—");
  });

  it("gives every rule its own icon", async () => {
    const icons = await Promise.all(
      Object.values(SupporterContributionLinkedViaEnum).map(async (rule) => {
        const wrapper = await mountWithDefaults(Component, {
          props: { linkedVia: rule },
        });

        return wrapper.find("[data-test='linked-via-pill'] i").classes().join();
      }),
    );

    expect(new Set(icons).size).toBe(icons.length);
  });
});
