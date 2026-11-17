import {
  type ChainContext,
  chainStarts,
  spliceHeld,
} from "@/frontend/components/Hangar/Planner/chain";
import { upgradeCost } from "@/frontend/components/Hangar/Planner/reach";
import {
  BuybackPledgeKindEnum,
  type HangarPlan,
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanModel,
  type HangarPlanResources,
  HangarPlanStartKindEnum,
  type HangarPlanUpgradeStep,
  type HangarPlanUpgradeStepInput,
  HangarPlanUpgradeSourceEnum,
} from "@/services/fyApi";

export type FitStep = {
  sourceKind: HangarPlanUpgradeSourceEnum;
  toModelId: string | null;
  hangarPledgeItemId: string | null;
  buybackPledgeId: string | null;
  priceOverride: number | null;
  usesBuybackToken: boolean;
  heldFrom?: string;
  price?: number | null;
  // The saved step this one is, for as long as it still starts where it did.
  saved?: HangarPlanUpgradeStep;
};

export type UpgradeFit = {
  upgradeId: string;
  sourceKind: HangarPlanUpgradeSourceEnum;
  from: HangarPlanModel;
  to: HangarPlanModel;
  candidate: HangarPlanCandidate;
  acquisition: HangarPlanAcquisition;
  saving: number;
  // What melting the upgrade instead would give back; using it spends that.
  credit: number | null;
  steps: HangarPlanUpgradeStepInput[];
};

type Held = {
  id: string;
  sourceKind: HangarPlanUpgradeSourceEnum;
  from: HangarPlanModel;
  to: HangarPlanModel;
  price: number | null;
  credit: number | null;
};

// Upgrades the user holds and no route spends yet.
const freeHeld = (resources: HangarPlanResources): Held[] => [
  ...resources.upgrades.flatMap((item) =>
    item.fromModel && item.toModel && item.quantity - item.usedCount > 0
      ? [
          {
            id: item.id,
            sourceKind: HangarPlanUpgradeSourceEnum.OWNED_CCU,
            from: item.fromModel,
            to: item.toModel,
            price: 0,
            credit: item.pledgeValue ?? null,
          },
        ]
      : [],
  ),
  ...resources.buybacks.flatMap((pledge) =>
    pledge.kind === BuybackPledgeKindEnum.UPGRADE &&
    !pledge.used &&
    pledge.upgradeFromModel &&
    pledge.upgradeToModel
      ? [
          {
            id: pledge.id,
            sourceKind: HangarPlanUpgradeSourceEnum.BUYBACK,
            from: pledge.upgradeFromModel,
            to: pledge.upgradeToModel,
            price: pledge.price ?? null,
            credit: null,
          },
        ]
      : [],
  ),
];

// A held upgrade starts on the ship it was sold for, wherever the route put it.
const heldStart = (
  step: HangarPlanUpgradeStep,
  resources: HangarPlanResources,
) => {
  if (step.hangarPledgeItemId) {
    return resources.upgrades.find(
      (item) => item.id === step.hangarPledgeItemId,
    )?.fromModel?.id;
  }
  if (step.buybackPledgeId) {
    return resources.buybacks.find(
      (pledge) => pledge.id === step.buybackPledgeId,
    )?.upgradeFromModel?.id;
  }
  return undefined;
};

const savedStep = (
  step: HangarPlanUpgradeStep,
  resources: HangarPlanResources,
): FitStep => ({
  sourceKind: step.sourceKind,
  toModelId: step.toModel.id,
  hangarPledgeItemId: step.hangarPledgeItemId ?? null,
  buybackPledgeId: step.buybackPledgeId ?? null,
  priceOverride: step.priceOverride ?? null,
  usesBuybackToken: step.usesBuybackToken,
  heldFrom:
    step.sourceKind === HangarPlanUpgradeSourceEnum.STORE
      ? undefined
      : (heldStart(step, resources) ?? step.fromModel.id),
  price: step.price,
  saved: step,
});

const heldStep = (held: Held): FitStep => ({
  sourceKind: held.sourceKind,
  toModelId: held.to.id,
  hangarPledgeItemId:
    held.sourceKind === HangarPlanUpgradeSourceEnum.OWNED_CCU ? held.id : null,
  buybackPledgeId:
    held.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK ? held.id : null,
  priceOverride: null,
  usesBuybackToken: held.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK,
  heldFrom: held.from.id,
  price: held.price,
});

const storeStep = (toModelId: string): FitStep => ({
  sourceKind: HangarPlanUpgradeSourceEnum.STORE,
  toModelId,
  hangarPledgeItemId: null,
  buybackPledgeId: null,
  priceOverride: null,
  usesBuybackToken: false,
});

const planModels = (plan: HangarPlan, resources: HangarPlanResources) => {
  const known = new Map<string, HangarPlanModel>();
  const add = (model?: HangarPlanModel | null) => {
    if (model) known.set(model.id, model);
  };

  resources.storeModels.forEach(add);
  plan.slots.forEach((slot) =>
    slot.candidates.forEach((candidate) => {
      add(candidate.model);
      candidate.acquisitions.forEach((acquisition) => {
        add(acquisition.startModel);
        acquisition.steps.forEach((step) => {
          add(step.fromModel);
          add(step.toModel);
        });
      });
    }),
  );
  resources.upgrades.forEach((item) => {
    add(item.fromModel);
    add(item.toModel);
  });
  resources.buybacks.forEach((pledge) => {
    add(pledge.upgradeFromModel);
    add(pledge.upgradeToModel);
  });

  return known;
};

const total = (prices: (number | null | undefined)[]) =>
  prices.some((price) => price === null || price === undefined)
    ? null
    : prices.reduce<number>((sum, price) => sum + (price ?? 0), 0);

const toInput = (step: FitStep): HangarPlanUpgradeStepInput => ({
  sourceKind: step.sourceKind,
  toModelId: step.toModelId as string,
  hangarPledgeItemId: step.hangarPledgeItemId,
  buybackPledgeId: step.buybackPledgeId,
  priceOverride: step.priceOverride,
  usesBuybackToken: step.usesBuybackToken,
});

// For each held upgrade no route spends yet, the complete route it makes
// cheapest, with what that saves. Upgrades that save nothing, or whose saving
// is unknown, are left out.
export const findUpgradeFits = (
  plan: HangarPlan,
  resources: HangarPlanResources,
  // Upgrades just spent whose use the resources do not count yet.
  spent: string[] = [],
): UpgradeFit[] => {
  const models = planModels(plan, resources);
  const model = (id: string) => models.get(id);

  const ctx: ChainContext<FitStep> = {
    model,
    heldFrom: (step) => step.heldFrom,
    storeStep,
    restart: (step) => ({ ...step, priceOverride: null, saved: undefined }),
  };

  const stepPrice = (step: FitStep, from: string | null) => {
    if (step.saved && step.saved.fromModel.id === from) return step.saved.price;
    if (step.sourceKind !== HangarPlanUpgradeSourceEnum.STORE) {
      return step.price;
    }
    const fromModel = from ? model(from) : undefined;
    const toModel = step.toModelId ? model(step.toModelId) : undefined;

    return fromModel && toModel ? upgradeCost(fromModel, toModel) : undefined;
  };

  const routes = plan.slots.flatMap((slot) =>
    slot.candidates.flatMap((candidate) =>
      candidate.acquisitions
        .filter(
          (acquisition) =>
            acquisition.routeComplete &&
            acquisition.startKind !== HangarPlanStartKindEnum.INGAME,
        )
        .map((acquisition) => ({ candidate, acquisition })),
    ),
  );

  return freeHeld(resources)
    .filter((held) => !spent.includes(held.id))
    .flatMap((held) => {
      let best: UpgradeFit | undefined;

      routes.forEach(({ candidate, acquisition }) => {
        const start = acquisition.startModel.id;
        const steps = acquisition.steps.map((step) =>
          savedStep(step, resources),
        );
        const before = total(steps.map((step) => step.price));
        if (before === null) return;

        const spliced = spliceHeld(
          start,
          steps,
          { step: heldStep(held), from: held.from.id, to: held.to.id },
          candidate.model.id,
          ctx,
        );
        if (!spliced) return;

        const starts = chainStarts(start, spliced);
        const after = total(
          spliced.map((step, index) => stepPrice(step, starts[index])),
        );
        if (after === null) return;

        const saving = Math.round((before - after) * 100) / 100;
        if (saving <= 0 || (best && best.saving >= saving)) return;

        best = {
          upgradeId: held.id,
          sourceKind: held.sourceKind,
          from: held.from,
          to: held.to,
          candidate,
          acquisition,
          saving,
          credit: held.credit,
          steps: spliced.map(toInput),
        };
      });

      return best ? [best] : [];
    })
    .sort((a, b) => b.saving - a.saving);
};
