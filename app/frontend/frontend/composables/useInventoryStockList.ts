import type { Ref } from "vue";
import type { InventoryStockRecord } from "@/frontend/types/logistics";

/**
 * The stock endpoints carry a position id to key rows on, but still take no
 * filter parameters, so the filtering is derived from the current route query
 * here.
 */
export const useInventoryStockList = (
  stockData: Ref<InventoryStockRecord[] | undefined>,
) => {
  const route = useRoute();

  const stockRecords = computed<InventoryStockRecord[]>(
    () => stockData.value ?? [],
  );

  const filteredStockRecords = computed<InventoryStockRecord[]>(() => {
    const nameFilter = (route.query.nameCont as string)?.toLowerCase();
    const categoryFilter = route.query.categoryEq as string;
    const qualityMin = route.query.qualityGteq
      ? Number(route.query.qualityGteq)
      : undefined;
    const qualityMax = route.query.qualityLteq
      ? Number(route.query.qualityLteq)
      : undefined;

    return stockRecords.value.filter((item) => {
      if (nameFilter && !item.name.toLowerCase().includes(nameFilter)) {
        return false;
      }
      if (categoryFilter && item.category !== categoryFilter) {
        return false;
      }
      if (qualityMin !== undefined || qualityMax !== undefined) {
        // Rows from the merged endpoints carry a range rather than a single
        // quality, so a filter keeps every row whose range reaches into it.
        const highest = item.qualityMax ?? item.quality;
        const lowest = item.qualityMin ?? item.quality;

        // Entries may carry no quality at all, and a row aggregated from only
        // those has nothing to compare against. Reading the absent value as 0
        // would answer both bounds - below every minimum, under every maximum.
        // The log view drops such rows, ransack comparing against NULL, so the
        // same filter must not leave them standing here.
        if (highest == null || lowest == null) {
          return false;
        }
        if (qualityMin !== undefined && highest < qualityMin) {
          return false;
        }
        if (qualityMax !== undefined && lowest > qualityMax) {
          return false;
        }
      }
      return true;
    });
  });

  return {
    stockRecords: filteredStockRecords,
  };
};
