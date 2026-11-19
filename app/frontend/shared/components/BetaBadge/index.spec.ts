import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { FeatureFlagName } from "@/services/fyApi";
import Component from "./index.vue";

const badge = async (feature: FeatureFlagName | FeatureFlagName[]) => {
  const wrapper = await mountWithDefaults(Component, { props: { feature } });

  return wrapper.find('[data-test="beta-badge"]');
};

describe("BetaBadge", () => {
  it("shows for a beta flag, with the hint as its label", async () => {
    const element = await badge(FeatureFlagName.DRESSING_ROOM);

    expect(element.exists()).toBe(true);
    expect(element.text()).toBe("Beta");
    expect(element.attributes("aria-label")).toContain("feedback");
  });

  it("stays out for a permanent flag", async () => {
    expect((await badge(FeatureFlagName.OAUTH_GITHUB)).exists()).toBe(false);
  });
});
