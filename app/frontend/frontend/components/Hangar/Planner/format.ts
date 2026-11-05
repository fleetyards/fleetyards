import { useI18n } from "@/shared/composables/useI18n";
import type {
  HangarPlanModel,
  HangarPlanPledgeItem,
  HangarPlanPledgeShip,
} from "@/services/fyApi";

export type PledgeDetails = {
  pledgeName?: string | null;
  pledgeItemCount?: number | null;
  // Besides the ship the pledge is read from.
  pledgeShips: HangarPlanPledgeShip[];
  pledgeItems: HangarPlanPledgeItem[];
};

// RSI counts what the sync keeps no record of, such as the game package or
// insurance-only items.
export const pledgeUnlisted = (pledge: PledgeDetails) => {
  const listed =
    1 +
    pledge.pledgeShips.length +
    pledge.pledgeItems.reduce((sum, item) => sum + item.quantity, 0);

  return Math.max((pledge.pledgeItemCount ?? 0) - listed, 0);
};

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

// How a hangar ship was pledged, said only where the hangar sync saw its pledge.
export const usePledgeNote = () => {
  const { t } = useI18n();

  return ({
    standalone,
    pledgeName,
  }: {
    standalone?: boolean | null;
    pledgeName?: string | null;
  }) => {
    if (standalone === null || standalone === undefined) return undefined;
    if (standalone) return t("hangarPlanner.pledge.standalone");

    return pledgeName
      ? t("hangarPlanner.pledge.inPackage", { name: pledgeName })
      : t("hangarPlanner.pledge.package");
  };
};
