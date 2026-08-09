import type { Ref } from "vue";
import type { InventoryStockRecord } from "@/frontend/types/logistics";

type StockItem = Omit<InventoryStockRecord, "id">;

/**
 * The stock endpoints return aggregates rather than records, so they have no
 * id to key rows on and no server-side filtering. This derives both from the
 * current route query.
 */
export const useInventoryStockList = (
  stockData: Ref<StockItem[] | undefined>,
) => {
  const route = useRoute();

  const stockRecords = computed<InventoryStockRecord[]>(
    () =>
      stockData.value?.map((item, index) => ({
        ...item,
        id: `${item.name}-${item.category}-${item.unit}-${index}`,
      })) ?? [],
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
      if (qualityMin !== undefined && (item.quality ?? 0) < qualityMin) {
        return false;
      }
      if (qualityMax !== undefined && (item.quality ?? 0) > qualityMax) {
        return false;
      }
      return true;
    });
  });

  return {
    stockRecords: filteredStockRecords,
  };
};
