import { describe, expect, it } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPledgeItemKindEnum,
  type HangarPlanModel,
} from "@/services/fyApi";
import Component from "./index.vue";

const model = (name: string): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice: 100,
});

const open = async (pledge: Record<string, unknown>) => {
  const wrapper = await mountWithDefaults(Component, {
    attachTo: document.body,
    props: {
      ship: { id: "vehicle", model: model("Aurora MR") },
      pledge: { pledgeShips: [], pledgeItems: [], ...pledge },
    },
  });
  const button = wrapper.find('[data-test="hangar-plan-pledge-info"]');

  button.element.dispatchEvent(
    new PointerEvent("pointerover", { bubbles: true, pointerType: "mouse" }),
  );
  button.element.dispatchEvent(
    new MouseEvent("click", { bubbles: true, detail: 1 }),
  );
  await flushPromises();

  const card = document.body.querySelector(
    '[data-test="hangar-plan-pledge-contents"]',
  );
  wrapper.unmount();

  return card?.textContent ?? "";
};

describe("Hangar/Planner/PledgeInfo", () => {
  it("opens on what the package holds, the ship itself included", async () => {
    const text = await open({
      pledgeName: "Package - Praetorian Pack",
      pledgeItemCount: 4,
      pledgeShips: [{ id: "other", model: model("Gladius") }],
      pledgeItems: [
        {
          id: "paint",
          name: "Gladius - Ghoul Paint",
          kind: HangarPledgeItemKindEnum.PAINT,
          quantity: 1,
        },
      ],
    });

    expect(text).toContain("Package - Praetorian Pack");
    expect(text).toContain("Aurora MR");
    expect(text).toContain("Gladius");
    expect(text).toContain("Gladius - Ghoul Paint");
    expect(text).toContain("1 more item");
  });

  it("names a package the sync kept no name for", async () => {
    expect(await open({})).toContain("In a package");
  });
});
