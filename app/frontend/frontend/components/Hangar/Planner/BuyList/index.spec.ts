import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanPurchaseKindEnum,
  HangarPlanSlotStateEnum,
  type HangarPlanModel,
  type HangarPlanPurchase,
  type HangarPlanSlot,
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

const slot = (id: string, label: string): HangarPlanSlot => ({
  id,
  label,
  position: 0,
  state: HangarPlanSlotStateEnum.DECIDED,
  filters: {},
  starts: [],
  candidates: [],
});

const purchase = (
  attrs: Partial<HangarPlanPurchase> & Pick<HangarPlanPurchase, "kind">,
): HangarPlanPurchase => ({
  fromModel: null,
  model: null,
  name: "",
  price: 0,
  quantity: 1,
  tokenCount: 0,
  slotIds: [],
  notOnSale: false,
  ...attrs,
});

const avenger = model("Avenger");
const cutlass = model("Cutlass");
const slots = [slot("hauler", "Hauler"), slot("miner", "Miner")];

describe("HangarPlannerBuyList", () => {
  it("says when there is nothing to buy", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { purchases: [], slots },
    });

    expect(wrapper.text()).toContain("Nothing to buy yet");
  });

  it("lists each purchase under its kind with the slots it is for", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots,
        purchases: [
          purchase({
            kind: HangarPlanPurchaseKindEnum.CCU,
            fromModel: avenger,
            model: cutlass,
            name: "Avenger → Cutlass",
            price: 60,
            quantity: 2,
            slotIds: ["hauler", "miner"],
            notOnSale: true,
          }),
          purchase({
            kind: HangarPlanPurchaseKindEnum.BUYBACK,
            model: cutlass,
            name: "Cutlass",
            price: 90,
            tokenCount: 1,
            slotIds: ["hauler"],
          }),
          purchase({
            kind: HangarPlanPurchaseKindEnum.EXTRA,
            name: "Cutlass - Ghoul",
            price: null,
            slotIds: ["miner"],
          }),
        ],
      },
    });

    const ccus = wrapper.find('[data-test="hangar-plan-buy-list-ccu"]');
    expect(ccus.text()).toContain("Upgrades from the store");
    expect(ccus.text()).toContain("Avenger");
    expect(ccus.text()).toContain("×2");
    expect(ccus.text()).toContain("$60");
    expect(ccus.text()).toContain("Hauler, Miner");
    expect(ccus.text()).toContain("Not on sale right now");

    const buybacks = wrapper.find('[data-test="hangar-plan-buy-list-buyback"]');
    expect(buybacks.text()).toContain("1 paid with a buy-back token");

    const extras = wrapper.find('[data-test="hangar-plan-buy-list-extra"]');
    expect(extras.text()).toContain("Cutlass - Ghoul");
    expect(extras.text()).toContain("Unknown");
  });
});
