export type InventoryReference = {
  name?: string;
  slug?: string;
};

/**
 * The game item an entry points at. `available` is false once the current
 * build stops shipping it: the entry still resolves, but the pickers no
 * longer offer the item for new ones.
 */
export type InventoryItemReference = {
  id?: string;
  type?: string;
  name?: string;
  slug?: string;
  available?: boolean;
};

/**
 * Structural shape shared by the generated Fleet* and Hangar* inventory
 * models, so the logistics components can render either without knowing
 * which owner the inventory belongs to.
 */
export type InventoryStockRecord = {
  id: string;
  slug?: string;
  name: string;
  category: string;
  unit: string;
  quality?: number | null;
  qualityMin?: number | null;
  qualityMax?: number | null;
  netQuantity: number;
  inventory?: InventoryReference;
};

export type InventoryVehicleReference = {
  id: string;
  name: string;
  serial?: string | null;
  model?: {
    name?: string;
    slug?: string;
    cargo?: number;
    personalInventory?: number;
  };
};

export type InventoryPanelRecord = {
  id: string | null;
  name: string;
  slug?: string | null;
  location?: string | null;
  entriesCount: number;
  totalScu?: number;
  totalUnits?: number;
  image?: { mediumUrl?: string };
  vehicle?: InventoryVehicleReference | null;
};

/**
 * Which inventory a logistics modal writes to, and through which endpoints. A
 * ship inventory has no slug worth addressing — two Ironclads share one — so it
 * is reached through the ship.
 */
export type InventoryTarget =
  { kind: "hangar"; slug: string } | { kind: "vehicle"; vehicleId: string };

export type InventoryLedgerRecord = {
  id: string;
  stockSlug?: string;
  name: string;
  category: string;
  unit: string;
  entryType: string;
  quality?: number;
  quantity: number;
  notes?: string;
  inventory?: InventoryReference;
  item?: InventoryItemReference | null;
};
