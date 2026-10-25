import {
  type FleetContract,
  type FleetContractDetail,
  FleetContractRewardTypeEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type ContractLike = Pick<
  FleetContract | FleetContractDetail,
  "reward" | "rewardType" | "maxReward" | "rewardRate" | "progress"
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

  // Lines paying different rates have no one rate to name, so the contract
  // reads as the most it can pay.
  const sharedRate = (contract: ContractLike) =>
    contract.rewardType === FleetContractRewardTypeEnum.PER_UNIT &&
    contract.rewardRate != null
      ? Number(contract.rewardRate)
      : null;

  const upTo = (contract: ContractLike) =>
    t("labels.fleets.contracts.maxReward", {
      amount: toUEC(Number(contract.maxReward)),
    });

  // Markup, like `toUEC` itself: the unit is muted.
  const rewardLabel = (contract: ContractLike) => {
    switch (contract.rewardType) {
      case FleetContractRewardTypeEnum.NONE:
        return t("labels.fleets.contracts.noReward");
      case FleetContractRewardTypeEnum.PER_UNIT: {
        const rate = sharedRate(contract);

        return rate == null ? upTo(contract) : toUEC(rate, rateUnit(contract));
      }
      default:
        return toUEC(Number(contract.reward));
    }
  };

  // The same figure as plain text, for a badge that cannot take markup. A rate
  // keeps its cents: 12.50 per SCU rounded to 13 would misstate the pay. Rates
  // that differ per line read as the most they pay, and the badge says so.
  const rewardFigure = (
    contract: ContractLike,
  ): { value: string; unit?: string; label?: string } => {
    const total = (amount: number) => ({
      value: String(toNumber(amount, "integer")),
      unit: t("number.units.uec"),
    });

    switch (contract.rewardType) {
      case FleetContractRewardTypeEnum.NONE:
        return { value: t("labels.fleets.contracts.noReward") };
      case FleetContractRewardTypeEnum.PER_UNIT: {
        const rate = sharedRate(contract);
        if (rate == null) {
          return {
            ...total(Number(contract.maxReward)),
            label: t("labels.fleets.contracts.rewardUpTo"),
          };
        }

        return {
          value: rate.toLocaleString(currentLocale(), {
            maximumFractionDigits: 2,
          }),
          unit: rateUnit(contract),
        };
      }
      default:
        return total(Number(contract.reward));
    }
  };

  // What a shared rate comes to once every line is delivered. Rates that
  // differ already read as this total, and a fixed reward is one.
  const maxRewardLabel = (contract: ContractLike) => {
    if (sharedRate(contract) == null || !Number(contract.maxReward)) {
      return null;
    }

    return upTo(contract);
  };

  return { paysReward, rewardLabel, rewardFigure, maxRewardLabel };
};
