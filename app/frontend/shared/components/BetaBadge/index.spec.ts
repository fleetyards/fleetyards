import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { FeatureFlagName } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => {
  const original = await importOriginal<typeof import("@/services/fyApi")>();
  const { ref } = await import("vue");

  return {
    ...original,
    useBetaFeatures: () => ({
      data: ref([
        original.FeatureFlagName.DRESSING_ROOM,
        original.FeatureFlagName.HANGAR_PLANNER,
        original.FeatureFlagName.HOMEPAGE_DASHBOARD,
        original.FeatureFlagName.FLEET_LOGISTICS,
      ]),
    }),
  };
});

const mount = (feature: FeatureFlagName | FeatureFlagName[]) =>
  mountWithDefaults(Component, { props: { feature } });

const badge = async (feature: FeatureFlagName | FeatureFlagName[]) =>
  (await mount(feature)).find('[data-test="beta-badge"]');

describe("BetaBadge", () => {
  it("shows for a flag users or fleets can switch on, with the hint as its label", async () => {
    const wrapper = await mount(FeatureFlagName.DRESSING_ROOM);
    const element = wrapper.find('[data-test="beta-badge"]');

    expect(element.exists()).toBe(true);
    expect(element.text()).toBe("Beta");
    expect(
      wrapper.find(`#${element.attributes("aria-describedby")}`).text(),
    ).toContain("feedback");
  });

  it("stays out for a flag nobody can switch on themselves", async () => {
    expect((await badge(FeatureFlagName.STARMAP)).exists()).toBe(false);
  });

  it("leaves the hint to the control it sits in", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { feature: FeatureFlagName.DRESSING_ROOM, inControl: true },
    });
    const element = wrapper.find('[data-test="beta-badge"]');

    expect(element.exists()).toBe(true);
    expect(element.attributes("tabindex")).toBeUndefined();
  });
});
