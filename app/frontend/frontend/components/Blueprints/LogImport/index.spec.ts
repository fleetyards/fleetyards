import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { FeatureFlagName } from "@/services/fyApi";

const enabled = new Set<FeatureFlagName>();

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (feature: FeatureFlagName) => enabled.has(feature),
  }),
}));

const Component = (await import("./index.vue")).default;

describe("BlueprintLogImportBtn", () => {
  it("is hidden while the feature is off", async () => {
    enabled.clear();

    const wrapper = await mountWithDefaults(Component);

    expect(
      wrapper.find("[data-test='open-blueprint-log-import']").exists(),
    ).toBe(false);
  });

  it("is offered once the feature is on", async () => {
    enabled.add(FeatureFlagName.BLUEPRINT_LOG_IMPORT);

    const wrapper = await mountWithDefaults(Component);

    expect(
      wrapper.find("[data-test='open-blueprint-log-import']").exists(),
    ).toBe(true);
  });
});
