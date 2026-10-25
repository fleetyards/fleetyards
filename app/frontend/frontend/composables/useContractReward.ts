import {
  type FleetContract,
  type FleetContractDetail,
  FleetContractRewardTypeEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type ContractLike = Pick<
  FleetContract | FleetContractDetail,
  "reward" | "rewardType" | "maxReward" | "progress"
>;

// The board's summary names the unit when every line shares one; the detail
// page's progress carries the lines themselves.
const sharedUnit = (contract: ContractLike) => {
  const progress = contract.progress;
  if (!("lines" in progress)) return progress.unit;

  const units = new Set(progress.lines.map((line) => line.unit));

  return units.size === 1 ? [...units][0] : null;
};

export const useContractReward = () => {
  const { t, toUEC, toNumber, currentLocale } = useI18n();

  const rateUnit = (contract: ContractLike) => {
    const unit = sharedUnit(contract);

    return t(
      `labels.fleets.contracts.rewardRate.${unit === "scu" || unit === "units" ? unit : "mixed"}`,
      { currency: t("number.units.uec") },
    );
  };

  const paysReward = (contract: ContractLike) =>
    contract.rewardType !== FleetContractRewardTypeEnum.NONE;

  // Markup, like `toUEC` itself: the unit is muted.
  const rewardLabel = (contract: ContractLike) => {
    switch (contract.rewardType) {
      case FleetContractRewardTypeEnum.NONE:
        return t("labels.fleets.contracts.noReward");
      case FleetContractRewardTypeEnum.PER_UNIT:
        return toUEC(Number(contract.reward), rateUnit(contract));
      default:
        return toUEC(Number(contract.reward));
    }
  };

  // The same figure as plain text, for a badge that cannot take markup. A rate
  // keeps its cents: 12.50 per SCU rounded to 13 would misstate the pay.
  const rewardFigure = (
    contract: ContractLike,
  ): { value: string; unit?: string } => {
    const amount = Number(contract.reward);

    switch (contract.rewardType) {
      case FleetContractRewardTypeEnum.NONE:
        return { value: t("labels.fleets.contracts.noReward") };
      case FleetContractRewardTypeEnum.PER_UNIT:
        return {
          value: amount.toLocaleString(currentLocale(), {
            maximumFractionDigits: 2,
          }),
          unit: rateUnit(contract),
        };
      default:
        return {
          value: String(toNumber(amount, "integer")),
          unit: t("number.units.uec"),
        };
    }
  };

  // What a rate comes to once every line is delivered. Only a rate needs it;
  // a fixed reward already is the total.
  const maxRewardLabel = (contract: ContractLike) => {
    if (contract.rewardType !== FleetContractRewardTypeEnum.PER_UNIT) {
      return null;
    }

    const max = Number(contract.maxReward);
    if (!max) return null;

    return t("labels.fleets.contracts.maxReward", { amount: toUEC(max) });
  };

  return { paysReward, rewardLabel, rewardFigure, maxRewardLabel };
};
