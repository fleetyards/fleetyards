import { useI18n } from "@/shared/composables/useI18n";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import type { HangarPlanAcquisition } from "@/services/fyApi";

export type RouteChainNode = {
  key: string;
  kind: string;
  ship: string;
  price?: string;
  missing?: boolean;
  // The upgrade that leads to this ship; absent on the ship a route starts with.
  link?: { source: string; price?: string };
};

export const useAcquisitionNodes = () => {
  const { t } = useI18n();
  const { money } = usePlanMoney();

  return (acquisition: HangarPlanAcquisition): RouteChainNode[] => [
    {
      key: "start",
      kind: t(`hangarPlanner.startKinds.${acquisition.startKind}`),
      ship: acquisition.startModel.name,
      price: money(acquisition.price),
      missing: acquisition.sourceMissing,
    },
    ...acquisition.steps.map((step, index) => ({
      key: step.id,
      kind: t("hangarPlanner.stepNumber", { number: index + 1 }),
      ship: step.toModel.name,
      missing: step.sourceMissing,
      link: {
        source: t(`hangarPlanner.upgradeSources.${step.sourceKind}`),
        price: money(step.price),
      },
    })),
  ];
};
