import type { Ref } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type PickedItem } from "@/frontend/components/Logistics/types";
import { type FilterOption, type InventoryCraftedRef } from "@/services/fyApi";

// One lot of a position: a quality grade, or a crafted part with the grades it
// was made from. A position holding several lots appears once per lot.
export type StockLot = {
  id: string;
  name: string;
  category: string;
  unit: string;
  netQuantity: number;
  quality?: number | null;
  item?: { id: string; type: PickedItem["type"] } | null;
  crafted?: InventoryCraftedRef;
};

/**
 * The options an inventory's stock offers a ledger form, keyed by row rather
 * than by position: a withdrawal comes out of one lot, and a position holding
 * several is several rows.
 */
export const useStockLots = (lots: Ref<StockLot[]>) => {
  const { t } = useI18n();

  // What tells two lots of one position apart in a list of names.
  const lotLabel = (lot: StockLot) => {
    if (lot.crafted) return t("labels.logistics.crafted.lot");

    if (lot.quality != null && lot.category === "commodity") {
      return t("labels.logistics.crafted.grade", { quality: lot.quality });
    }

    return undefined;
  };

  const lotOptions = computed<FilterOption[]>(() =>
    lots.value.map((lot, index) => ({
      value: String(index),
      label: [
        lot.name,
        lotLabel(lot),
        `${lot.netQuantity} ${t(`labels.logistics.units.${lot.unit}`)}`,
      ]
        .filter(Boolean)
        .join(" · "),
    })),
  );

  // A deposit joins a position, whichever lot it lands in, so each position is
  // offered once.
  const positionOptions = computed<FilterOption[]>(() =>
    lots.value
      .map((lot, index) => ({ lot, index }))
      .filter(
        ({ lot }, at, rows) =>
          rows.findIndex((row) => row.lot.id === lot.id) === at,
      )
      .map(({ lot, index }) => ({
        value: String(index),
        label: `${lot.name} (${t(`labels.logistics.categories.${lot.category}`)})`,
      })),
  );

  const lotAt = (key?: string) =>
    key === undefined ? undefined : lots.value[Number(key)];

  return { lotOptions, positionOptions, lotAt };
};
