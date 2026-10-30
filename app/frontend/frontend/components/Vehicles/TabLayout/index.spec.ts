import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

describe("VehicleTabLayout", () => {
  it("puts the side column beside the content under the full header", async () => {
    const wrapper = await mountWithDefaults(Component, {});

    expect(wrapper.classes()).toContain("vehicle-tab-layout--split");
  });
});
