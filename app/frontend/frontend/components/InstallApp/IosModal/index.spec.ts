import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

describe("InstallAppIosModal", () => {
  it("walks through share, add to home screen and confirm", async () => {
    wrapper = await mountWithDefaults<typeof Component>(Component);

    const steps = wrapper.findAll(
      "[data-test='install-app-ios-steps'] .install-app-ios__step",
    );

    expect(steps.map((step) => step.text())).toEqual([
      "Tap the Share button in the browser toolbar.",
      "Choose “Add to Home Screen”. You may have to scroll down to find it.",
      "Tap “Add”. FleetYards now opens from your Home Screen like any other app.",
    ]);
  });
});
