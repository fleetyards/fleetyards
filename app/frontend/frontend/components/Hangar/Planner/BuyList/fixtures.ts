import {
  HangarPlanSlotStateEnum,
  HangarPlanStartKindEnum,
  HangarPlanUpgradeSourceEnum,
  type HangarPlanAcquisition,
  type HangarPlanModel,
  type HangarPlanSlot,
  type HangarPlanUpgradeStep,
} from "@/services/fyApi";

export const model = (
  name: string,
  attrs: Partial<HangarPlanModel> = {},
): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice: 100,
  ...attrs,
});

export const step = (
  from: HangarPlanModel,
  to: HangarPlanModel,
  attrs: Partial<HangarPlanUpgradeStep> = {},
): HangarPlanUpgradeStep => ({
  id: `${from.id}-${to.id}`,
  sourceKind: HangarPlanUpgradeSourceEnum.STORE,
  fromModel: from,
  toModel: to,
  usesBuybackToken: false,
  price: 25,
  sourceMissing: false,
  ...attrs,
});

export const acquisition = (
  start: HangarPlanModel,
  attrs: Partial<HangarPlanAcquisition> = {},
): HangarPlanAcquisition => ({
  id: `acquisition-${start.id}`,
  startKind: HangarPlanStartKindEnum.OWNED,
  startModel: start,
  price: 0,
  routeComplete: true,
  sourceMissing: false,
  usesBuybackToken: false,
  steps: [],
  ...attrs,
});

export const decidedSlot = (
  label: string,
  route: HangarPlanAcquisition,
  attrs: Partial<HangarPlanSlot> = {},
): HangarPlanSlot => ({
  id: `slot-${label}`,
  label,
  position: 0,
  state: HangarPlanSlotStateEnum.DECIDED,
  filters: {},
  starts: [],
  candidates: [
    {
      id: `candidate-${label}`,
      position: 0,
      model: route.steps.at(-1)?.toModel ?? route.startModel,
      modelModuleIds: [],
      modelUpgradeIds: [],
      matchesFilters: true,
      acquisitions: [route],
    },
  ],
  ...attrs,
});
