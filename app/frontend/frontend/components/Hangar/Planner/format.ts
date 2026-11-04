import { useI18n } from "@/shared/composables/useI18n";
import type { HangarPlanModel } from "@/services/fyApi";

// A pick row shows the manufacturer's icon, so it names the manufacturer only
// where there is none.
export const manufacturerText = (model: HangarPlanModel) =>
  model.manufacturerIcon ? undefined : (model.manufacturerName ?? undefined);

// Prices a plan cannot know stay visibly unknown, and a route that costs
// nothing says so rather than reading as a missing value.
export const usePlanMoney = () => {
  const { t, toDollar } = useI18n();

  const money = (value?: number | null) => {
    if (value === null || value === undefined) {
      return t("hangarPlanner.unknownPrice");
    }

    if (value === 0) {
      return t("hangarPlanner.free");
    }

    return toDollar(value);
  };

  // A total reads as an amount even when it is nothing.
  const amount = (value: number) => (value === 0 ? "$0.00" : toDollar(value));

  const range = (min: number, max: number) =>
    min === max ? amount(min) : `${amount(min)} – ${amount(max)}`;

  // A plan whose credit outweighs its spend hands money back, which reads
  // better as credit than as a range of two negative costs.
  const net = (min: number, max: number) =>
    max < 0
      ? t("hangarPlanner.comparison.meltCredit", { value: range(-max, -min) })
      : range(min, max);

  // Units without a start, from their cheapest start to the store price.
  const startRange = (min?: number | null, max?: number | null) =>
    typeof min === "number" && typeof max === "number"
      ? range(min, max)
      : money(max);

  return { money, amount, range, net, startRange };
};
