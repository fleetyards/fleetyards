import { describe, expect, it } from "vitest";
import {
  HangarPlanSlotStateEnum,
  HangarPlanStartKindEnum,
  HangarPlanUpgradeSourceEnum,
} from "@/services/fyApi";
import { buildBuyList } from "./buyList";
import { acquisition, decidedSlot, model, step } from "./fixtures";

const avenger = model("Avenger");
const cutlass = model("Cutlass");
const freelancer = model("Freelancer");
const constellation = model("Constellation", { onSale: false });

describe("buildBuyList", () => {
  it("lists the store upgrades, buy-backs and store ships a route needs", () => {
    const groups = buildBuyList([
      decidedSlot(
        "Hauler",
        acquisition(avenger, {
          startKind: HangarPlanStartKindEnum.STORE,
          price: 50,
          steps: [
            step(avenger, cutlass, { price: 30 }),
            step(cutlass, freelancer, {
              sourceKind: HangarPlanUpgradeSourceEnum.BUYBACK,
              price: 20,
              usesBuybackToken: true,
            }),
          ],
        }),
      ),
    ]);

    expect(groups.map((group) => group.section)).toEqual([
      "ccus",
      "buybacks",
      "ships",
    ]);
    expect(groups[0].entries[0]).toMatchObject({
      fromModel: avenger,
      model: cutlass,
      price: 30,
      quantity: 1,
      slotLabels: ["Hauler"],
    });
    expect(groups[1].entries[0]).toMatchObject({
      model: freelancer,
      usesBuybackToken: true,
    });
    expect(groups[2].total).toBe(50);
  });

  it("leaves out what the hangar already holds", () => {
    const groups = buildBuyList([
      decidedSlot(
        "Hauler",
        acquisition(avenger, {
          steps: [
            step(avenger, cutlass, {
              sourceKind: HangarPlanUpgradeSourceEnum.OWNED_CCU,
            }),
          ],
        }),
      ),
    ]);

    expect(groups).toEqual([]);
  });

  it("counts the same upgrade bought for several slots once, with a quantity", () => {
    const route = () =>
      acquisition(avenger, { steps: [step(avenger, cutlass)] });

    const [ccus] = buildBuyList([
      decidedSlot("First", route()),
      decidedSlot("Second", route()),
    ]);

    expect(ccus.entries).toHaveLength(1);
    expect(ccus.entries[0].quantity).toBe(2);
    expect(ccus.entries[0].slotLabels).toEqual(["First", "Second"]);
    expect(ccus.total).toBe(50);
  });

  it("skips undecided slots and routes still being planned", () => {
    const route = acquisition(avenger, { steps: [step(avenger, cutlass)] });

    expect(
      buildBuyList([
        decidedSlot("Undecided", route, {
          state: HangarPlanSlotStateEnum.UNDECIDED,
        }),
        decidedSlot("Unfinished", { ...route, routeComplete: false }),
      ]),
    ).toEqual([]);
  });

  it("flags upgrades not on sale and prices nobody knows", () => {
    const [ccus] = buildBuyList([
      decidedSlot(
        "Explorer",
        acquisition(avenger, {
          steps: [step(avenger, constellation, { price: null })],
        }),
      ),
    ]);

    expect(ccus.entries[0].notOnSale).toBe(true);
    expect(ccus.hasUnknownPrice).toBe(true);
    expect(ccus.total).toBe(0);
  });
});
