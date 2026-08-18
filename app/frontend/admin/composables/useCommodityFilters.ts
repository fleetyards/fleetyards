import { type CommodityQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useCommodityFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<CommodityQuery>({
    updateCallback,
  });
};
