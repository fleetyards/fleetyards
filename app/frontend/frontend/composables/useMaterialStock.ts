import { useQueries } from "@tanstack/vue-query";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  useHangarAllInventoryStock,
  useMyFleets,
  getFleetAllInventoryStockQueryOptions,
  FeatureFlagName,
  type HangarInventoryStockItem,
  type FleetInventoryStockItem,
} from "@/services/fyApi";

export type MaterialStock = {
  id: string;
  name: string;
  /** Where it sits: a ship, or an inventory made by hand. */
  inventoryName?: string;
  inventorySlug?: string;
  vehicleName?: string;
  /** The fleet, where the stock is a fleet's rather than the reader's own. */
  ownerName?: string;
  ownerSlug?: string;
  quantity: number;
  unit?: string;
  /** The grades held. One entry where every entry agrees on it. */
  qualities: number[];
};

export type MaterialStockSources = {
  own: MaterialStock[];
  fleet: MaterialStock[];
};

// A recipe measures bulk in SCU and counts gems individually -- 298 of the
// 4,289 cost options are the counted kind. An inventory cannot say the same:
// a commodity position is forced to SCU (`UNITS_BY_CATEGORY`), whatever the
// game counts it in. So the two units agree only for the bulk ones, and the
// holding can be compared with what the recipe asks for only there. Gating on
// the unit instead just hid real stock.
const BULK_COST_TYPE = "resource";
const BULK_UNIT = "scu";

type StockRow = HangarInventoryStockItem | FleetInventoryStockItem;

const toStock = (
  position: StockRow,
  owner?: { name?: string; slug?: string },
): MaterialStock => {
  const qualities = [position.qualityMin, position.qualityMax].filter(
    (value): value is number => value !== undefined && value !== null,
  );

  return {
    id: position.id,
    name: position.name,
    inventoryName: position.inventory?.name,
    inventorySlug: position.inventory?.slug,
    vehicleName: position.inventory?.vehicleName,
    ownerName: owner?.name,
    ownerSlug: owner?.slug,
    quantity: position.netQuantity,
    unit: position.unit,
    qualities: [...new Set(qualities)],
  };
};

const indexByItem = (
  rows: { row: StockRow; owner?: { name?: string; slug?: string } }[],
) => {
  const held = new Map<string, MaterialStock[]>();

  rows.forEach(({ row, owner }) => {
    const itemId = row.item?.id;
    // A free-text entry, or a position whose entries disagree on what they
    // point at. Neither can be matched to a material.
    if (!itemId) return;

    held.set(itemId, [...(held.get(itemId) || []), toStock(row, owner)]);
  });

  return held;
};

/**
 * What the reader already has that a recipe asks for.
 *
 * Matched on the catalogue record the stock position points at, never on its
 * name: a position is named by whoever wrote it down, so "iron ore" against
 * the commodity "Iron" would both miss and mis-match.
 *
 * Their own hangar and their fleets' stores are kept apart rather than pooled.
 * A fleet's stock is not the reader's to spend -- it says "this exists and you
 * can ask for it", which is a different answer.
 */
export const useMaterialStock = () => {
  const { isAuthenticated } = storeToRefs(useSessionStore());
  const { isFeatureEnabled } = useFeatures();

  // The endpoints are gated twice over, and a public catalogue page is mostly
  // read by people who are neither signed in nor running inventories: asking
  // anyway would answer 401 or 403 for most of them.
  const hangarEnabled = computed(
    () =>
      isAuthenticated.value &&
      isFeatureEnabled(FeatureFlagName.HANGAR_INVENTORIES),
  );

  const fleetEnabled = computed(
    () =>
      isAuthenticated.value &&
      isFeatureEnabled(FeatureFlagName.FLEET_LOGISTICS),
  );

  const { data: hangarStock } = useHangarAllInventoryStock(undefined, {
    query: { enabled: hangarEnabled, retry: false },
  });

  const { data: fleets } = useMyFleets({
    query: { enabled: fleetEnabled, retry: false },
  });

  // Fleet stock is answered one fleet at a time, so a reader in three fleets
  // asks three times. They resolve independently, and one fleet refusing does
  // not take the others with it.
  const fleetList = computed(() => fleets.value ?? []);

  const fleetStock = useQueries({
    queries: computed(() =>
      fleetList.value.map((fleet) =>
        getFleetAllInventoryStockQueryOptions(fleet.slug, {
          query: { enabled: fleetEnabled, retry: false },
        }),
      ),
    ),
  });

  const ownIndex = computed(() =>
    indexByItem((hangarStock.value ?? []).map((row) => ({ row }))),
  );

  const fleetIndex = computed(() =>
    indexByItem(
      fleetStock.value.flatMap((result, at) =>
        (result.data ?? []).map((row: FleetInventoryStockItem) => ({
          row,
          owner: {
            name: fleetList.value[at]?.name,
            slug: fleetList.value[at]?.slug,
          },
        })),
      ),
    ),
  );

  /**
   * The stock that would actually fill this slot.
   *
   * A row holding less than the recipe asks for is not an answer to "can I
   * make this", so it is left out rather than shown as a near miss.
   */
  const forCommodity = (
    commodityId?: string,
    needed?: number | null,
    costType?: string | null,
  ): MaterialStockSources => {
    if (!commodityId) return { own: [], fleet: [] };

    // Comparable only where both sides are in SCU. A recipe asking for 170
    // gems against a holding of 10 SCU is not a comparison, and answering
    // "not enough" there would be a made-up claim rather than a filter.
    const comparable = costType === BULK_COST_TYPE;

    const usable = (entries: MaterialStock[]) =>
      entries.filter((entry) => {
        // A slot with no stated amount asks for nothing in particular, so any
        // holding of the right material counts.
        if (needed === undefined || needed === null) return true;
        if (!comparable || entry.unit !== BULK_UNIT) return true;

        return entry.quantity >= needed;
      });

    return {
      own: usable(ownIndex.value.get(commodityId) || []),
      fleet: usable(fleetIndex.value.get(commodityId) || []),
    };
  };

  return { forCommodity };
};
