import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

describe("Hangar/Planner/SlotPlaceholders", () => {
  it("hands the placeholder's role over as the label of the first slot", async () => {
    const wrapper = await mountWithDefaults(Component);

    await wrapper
      .find('[data-test="hangar-plan-placeholder-cargo"] button')
      .trigger("click");

    expect(wrapper.emitted("add")).toEqual([["Cargo hauler"]]);
  });
});
