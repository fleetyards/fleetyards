import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required } from "@vee-validate/rules";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { FeatureFlagName } from "@/services/fyApi";

const { mutateAsync } = vi.hoisted(() => ({
  mutateAsync: vi.fn(() => Promise.resolve({})),
}));

vi.mock("@/services/fyApi", async (importOriginal) => {
  const original = await importOriginal<typeof import("@/services/fyApi")>();
  const { ref } = await import("vue");

  return {
    ...original,
    useBetaFeatures: () => ({
      data: ref([original.FeatureFlagName.HANGAR_PLANNER]),
    }),
    useCreateFeedback: () => ({ mutateAsync, isPending: ref(false) }),
  };
});

import Component from "./index.vue";

defineRule("required", required);

describe("FeedbackModal", () => {
  it("sends the message with the feature and page it was opened for", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        feature: FeatureFlagName.HANGAR_PLANNER,
        pagePath: "/hangar/planner",
      },
    });

    await wrapper
      .find('[data-test="feedback-message"] textarea')
      .setValue("  Dragging is slow  ");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith({
      data: {
        message: "Dragging is slow",
        featureName: FeatureFlagName.HANGAR_PLANNER,
        pagePath: "/hangar/planner",
      },
    });
  });

  it("sends nothing without a message", async () => {
    mutateAsync.mockClear();
    const wrapper = await mountWithDefaults(Component, { props: {} });

    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
  });
});
