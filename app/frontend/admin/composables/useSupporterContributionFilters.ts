import { type SupporterContributionQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useSupporterContributionFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<SupporterContributionQuery>({
    updateCallback,
  });
};
