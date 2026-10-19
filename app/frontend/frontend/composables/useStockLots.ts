import type { Ref } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type PickedItem } from "@/frontend/components/Logistics/types";
import { type CraftedPart } from "@/frontend/composables/craftedComponent";
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

// Stable across a refetch, unlike an index: the position, the grade and what
// the part was crafted from are what tell a lot apart.
export const lotKey = (lot: Pick<StockLot, "id" | "quality" | "crafted">) =>
  JSON.stringify([
    lot.id,
    lot.quality ?? null,
    lot.crafted?.blueprint.id ?? null,
    Object.entries(lot.crafted?.qualities || {}).sort(([a], [b]) =>
      a.localeCompare(b),
    ),
  ]);

/**
 * What a withdrawal out of a crafted lot carries besides its grade: the part
 * and the grades it was made from, without which it would come out of stock
 * that was never crafted.
 */
export const lotEntry = (
  lot: StockLot,
): { item?: PickedItem; crafted?: CraftedPart } => {
  if (!lot.crafted || !lot.item) return {};

  return {
    item: { type: lot.item.type, id: lot.item.id, name: lot.name },
    crafted: {
      blueprintId: lot.crafted.blueprint.id,
      blueprintSlug: lot.crafted.blueprint.slug,
      qualities: lot.crafted.qualities,
    },
  };
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
    lots.value.map((lot) => ({
      value: lotKey(lot),
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
      .filter(
        (lot, at, rows) => rows.findIndex((row) => row.id === lot.id) === at,
      )
      .map((lot) => ({
        value: lotKey(lot),
        label: `${lot.name} (${t(`labels.logistics.categories.${lot.category}`)})`,
      })),
  );

  // A cleared select reports null as often as undefined; neither is a lot.
  const lotAt = (key?: string | null) =>
    key ? lots.value.find((lot) => lotKey(lot) === key) : undefined;

  return { lotOptions, positionOptions, lotAt };
};
