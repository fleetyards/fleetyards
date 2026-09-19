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
// 4,289 cost options are the counted kind. An inventory can now say either,
// so both sides of the comparison have a unit and the two no longer have to
// match: `pieceVolume` is what one piece takes up in SCU, which converts
// between them.
//
// Where there is no rate -- a bulk material has no single piece to measure --
// a holding in the other unit still cannot be compared, and is shown rather
// than judged. Answering "not enough" there would be a made-up claim.
const BULK_COST_TYPE = "resource";
const BULK_UNIT = "scu";
const PIECE_UNIT = "units";

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
    pieceVolume?: number | null,
  ): MaterialStockSources => {
    if (!commodityId) return { own: [], fleet: [] };

    // The unit the recipe states this slot's cost in.
    const costUnit = costType === BULK_COST_TYPE ? BULK_UNIT : PIECE_UNIT;

    /** The holding, restated in the unit the recipe asked for. */
    const inCostUnit = (entry: MaterialStock) => {
      if (entry.unit === costUnit) return entry.quantity;
      if (!pieceVolume) return undefined;

      return entry.unit === BULK_UNIT
        ? entry.quantity / pieceVolume
        : entry.quantity * pieceVolume;
    };

    const usable = (entries: MaterialStock[]) =>
      entries.filter((entry) => {
        // A slot with no stated amount asks for nothing in particular, so any
        // holding of the right material counts.
        if (needed === undefined || needed === null) return true;

        const amount = inCostUnit(entry);

        // No rate to convert by, so there is no comparison to make and none
        // is claimed -- the holding is shown as it stands.
        if (amount === undefined) return true;

        return amount >= needed;
      });

    return {
      own: usable(ownIndex.value.get(commodityId) || []),
      fleet: usable(fleetIndex.value.get(commodityId) || []),
    };
  };

  return { forCommodity };
};
