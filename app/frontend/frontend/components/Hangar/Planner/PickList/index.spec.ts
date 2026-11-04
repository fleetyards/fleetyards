import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanCcuIntoEnum,
  HangarPlanCcuOutOfEnum,
  type HangarPlanModel,
} from "@/services/fyApi";
import Component from "./index.vue";

const ship = (manufacturerIcon: string | null): HangarPlanModel => ({
  id: "polaris",
  name: "Polaris",
  slug: "polaris",
  manufacturerName: "Roberts Space Industries",
  manufacturerIcon,
  onSale: false,
  ccuInto: HangarPlanCcuIntoEnum.SALES_ONLY,
  ccuOutOf: HangarPlanCcuOutOfEnum.KNOWN,
});

describe("Hangar/Planner/PickList", () => {
  it("leads a ship's row with its manufacturer's icon and lists its tags", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        name: "ends",
        empty: "None",
        actions: true,
        items: [
          {
            id: "polaris",
            title: "Polaris",
            ship: ship("https://cdn.test/rsi.png"),
            tags: [
              { label: "New slot" },
              { label: "CCU only during sales", variant: "warning" },
            ],
          },
        ],
      },
    });

    const icon = wrapper.find(".pick-list__icon");
    expect(icon.attributes("src")).toBe("https://cdn.test/rsi.png");
    expect(icon.attributes("alt")).toBe("Roberts Space Industries");
    expect(
      wrapper.findAll('[data-test="pick-list-tag"]').map((tag) => tag.text()),
    ).toEqual(["New slot", "CCU only during sales"]);
  });
});
