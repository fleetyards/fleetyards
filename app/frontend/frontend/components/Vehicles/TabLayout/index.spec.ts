import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

const vehicleOverviewEnabled = ref(false);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: () => vehicleOverviewEnabled.value,
  }),
}));

describe("VehicleTabLayout", () => {
  it("puts the side column beside the content under the full header", async () => {
    vehicleOverviewEnabled.value = true;

    const wrapper = await mountWithDefaults(Component, {});

    expect(wrapper.classes()).toContain("vehicle-tab-layout--split");
  });

  it("stacks it over the content beside the old tab column", async () => {
    vehicleOverviewEnabled.value = false;

    const wrapper = await mountWithDefaults(Component, {});

    expect(wrapper.classes()).not.toContain("vehicle-tab-layout--split");
  });
});
