import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { FeatureFlagName } from "@/services/fyApi";
import { ref, type Plugin } from "vue";
import { OPEN_FEEDBACK } from "@/shared/utils/BetaFeatures";
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
        original.FeatureFlagName.PAINT_BOOTH,
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

  describe("where feedback can be sent", () => {
    const withFeedback = (
      open: (feature?: FeatureFlagName) => void,
    ): Plugin => ({
      install: (app) => app.provide(OPEN_FEEDBACK, ref(open)),
    });

    it("opens the form for the beta flag of the gate", async () => {
      const open = vi.fn();
      const wrapper = await mountWithDefaults(Component, {
        props: {
          feature: [FeatureFlagName.STARMAP, FeatureFlagName.HANGAR_PLANNER],
        },
        plugins: [withFeedback(open)],
      });
      const element = wrapper.find('[data-test="beta-badge"]');

      expect(element.element.tagName).toBe("BUTTON");
      await element.trigger("click");

      expect(open).toHaveBeenCalledWith(FeatureFlagName.HANGAR_PLANNER);
    });

    it("leaves a pill inside a control to the control", async () => {
      const wrapper = await mountWithDefaults(Component, {
        props: { feature: FeatureFlagName.DRESSING_ROOM, inControl: true },
        plugins: [withFeedback(vi.fn())],
      });

      expect(wrapper.find('[data-test="beta-badge"]').element.tagName).toBe(
        "SPAN",
      );
    });
  });
});
