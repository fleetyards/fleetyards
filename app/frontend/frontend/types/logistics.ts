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
  quality?: number;
  qualityMin?: number;
  qualityMax?: number;
  netQuantity: number;
  inventory?: InventoryReference;
};

export type InventoryPanelRecord = {
  id: string;
  name: string;
  slug: string;
  location?: string;
  itemCount: number;
  totalScu?: number;
  totalUnits?: number;
  image?: { mediumUrl?: string };
};

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
