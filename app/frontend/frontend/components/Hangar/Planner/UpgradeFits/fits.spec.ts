import { describe, expect, it } from "vitest";
import {
  BuybackPledgeKindEnum,
  type HangarPlan,
  type HangarPlanAcquisition,
  type HangarPlanModel,
  type HangarPlanResources,
  HangarPlanStartKindEnum,
  type HangarPlanUpgradeResource,
  type HangarPlanUpgradeStep,
  HangarPlanUpgradeSourceEnum,
} from "@/services/fyApi";
import { findUpgradeFits } from "./fits";

const model = (name: string, pledgePrice: number): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice,
});

const aurora = model("Aurora", 30);
const cutlass = model("Cutlass", 110);
const taurus = model("Taurus", 150);
const carrack = model("Carrack", 600);

const storeStep = (
  from: HangarPlanModel,
  to: HangarPlanModel,
): HangarPlanUpgradeStep => ({
  id: `step-${to.id}`,
  sourceKind: HangarPlanUpgradeSourceEnum.STORE,
  fromModel: from,
  toModel: to,
  usesBuybackToken: false,
  sourceMissing: false,
  price: (to.pledgePrice ?? 0) - (from.pledgePrice ?? 0),
});

const route: HangarPlanAcquisition = {
  id: "route",
  startKind: HangarPlanStartKindEnum.OWNED,
  startModel: aurora,
  price: 0,
  routeComplete: true,
  sourceMissing: false,
  usesBuybackToken: false,
  steps: [storeStep(aurora, cutlass), storeStep(cutlass, carrack)],
};

const planWith = (acquisition: HangarPlanAcquisition) =>
  ({
    id: "plan",
    slots: [
      {
        candidates: [
          {
            id: "candidate",
            position: 0,
            model: carrack,
            modelModuleIds: [],
            modelUpgradeIds: [],
            matchesFilters: true,
            acquisitions: [acquisition],
          },
        ],
      },
    ],
  }) as unknown as HangarPlan;

const ccu = (
  id: string,
  from: HangarPlanModel,
  to: HangarPlanModel,
  usedCount = 0,
): HangarPlanUpgradeResource => ({
  id,
  name: `Upgrade - ${from.name} to ${to.name}`,
  quantity: 1,
  usedCount,
  fromModel: from,
  toModel: to,
});

const resourcesWith = (
  attrs: Partial<HangarPlanResources>,
): HangarPlanResources => ({
  vehicles: [],
  upgrades: [],
  buybacks: [],
  bundled: [],
  storeModels: [aurora, cutlass, taurus, carrack],
  ...attrs,
});

describe("Hangar/Planner/UpgradeFits/fits", () => {
  it("finds the route a free CCU makes cheaper, with the steps it would have", () => {
    const fits = findUpgradeFits(
      planWith(route),
      resourcesWith({ upgrades: [ccu("ccu-aurora", aurora, taurus)] }),
    );

    expect(fits).toHaveLength(1);
    expect(fits[0]).toMatchObject({
      upgradeId: "ccu-aurora",
      saving: 120,
      steps: [
        {
          sourceKind: HangarPlanUpgradeSourceEnum.OWNED_CCU,
          hangarPledgeItemId: "ccu-aurora",
          toModelId: "Taurus",
        },
        {
          sourceKind: HangarPlanUpgradeSourceEnum.STORE,
          toModelId: "Carrack",
          priceOverride: null,
        },
      ],
    });
  });

  it("leaves out upgrades already spent and upgrades that fit no route", () => {
    expect(
      findUpgradeFits(
        planWith(route),
        resourcesWith({
          upgrades: [
            ccu("spent", aurora, taurus, 1),
            ccu("beyond", carrack, model("Idris", 1500)),
          ],
        }),
      ),
    ).toEqual([]);
  });

  it("leaves out a buy-back upgrade that costs more than the steps it replaces", () => {
    const buyback = (price: number) =>
      resourcesWith({
        buybacks: [
          {
            id: `buyback-${price}`,
            name: "Upgrade - Cutlass to Carrack",
            kind: BuybackPledgeKindEnum.UPGRADE,
            price,
            used: false,
            lifetimeInsurance: false,
            insuranceKnown: false,
            models: [],
            upgradeFromModel: cutlass,
            upgradeToModel: carrack,
          },
        ],
      });

    expect(findUpgradeFits(planWith(route), buyback(500))).toEqual([]);
    expect(findUpgradeFits(planWith(route), buyback(400))[0]).toMatchObject({
      saving: 90,
      steps: [
        { toModelId: "Cutlass" },
        { buybackPledgeId: "buyback-400", usesBuybackToken: true },
      ],
    });
  });

  it("does not suggest anything for a route still being planned", () => {
    expect(
      findUpgradeFits(
        planWith({ ...route, routeComplete: false }),
        resourcesWith({ upgrades: [ccu("ccu-aurora", aurora, taurus)] }),
      ),
    ).toEqual([]);
  });
});
