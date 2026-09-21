import { type CommodityQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useCommodityFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<CommodityQuery>({ updateCallback });
};
