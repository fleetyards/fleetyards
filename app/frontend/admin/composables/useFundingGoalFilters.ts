import { type FundingGoalQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useFundingGoalFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<FundingGoalQuery>({
    updateCallback,
  });
};
