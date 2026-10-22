import { useI18n } from "@/shared/composables/useI18n";

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

  return { money, amount, range };
};
