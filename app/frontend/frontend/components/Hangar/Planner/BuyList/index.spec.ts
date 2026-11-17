import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { HangarPlanStartKindEnum } from "@/services/fyApi";
import Component from "./index.vue";
import { acquisition, decidedSlot, model, step } from "./fixtures";

const avenger = model("Avenger");
const cutlass = model("Cutlass");

describe("HangarPlannerBuyList", () => {
  it("says when there is nothing to buy", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { slots: [] },
    });

    expect(wrapper.text()).toContain("Nothing to buy yet");
    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-total"]').exists(),
    ).toBe(false);
  });

  it("lists each purchase under its section with a total", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots: [
          decidedSlot(
            "Hauler",
            acquisition(avenger, {
              startKind: HangarPlanStartKindEnum.STORE,
              price: 50,
              steps: [step(avenger, cutlass, { price: 30 })],
            }),
          ),
        ],
      },
    });

    const ccus = wrapper.find('[data-test="hangar-plan-buy-list-ccus"]');
    expect(ccus.text()).toContain("Upgrades from the store");
    expect(ccus.text()).toContain("Avenger");
    expect(ccus.text()).toContain("Cutlass");
    expect(ccus.text()).toContain("$30");
    expect(ccus.text()).toContain("Hauler");

    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-ships"]').text(),
    ).toContain("$50");
    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-total"]').text(),
    ).toContain("$80");
  });
});
