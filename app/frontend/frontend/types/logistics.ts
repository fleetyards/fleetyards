export type InventoryReference = {
  name?: string;
  slug?: string;
};

/**
 * Structural shape shared by the generated Fleet* and Hangar* inventory
 * models, so the logistics components can render either without knowing
 * which owner the inventory belongs to.
 */
export type InventoryStockRecord = {
  id: string;
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
  name: string;
  category: string;
  unit: string;
  entryType: string;
  quality?: number;
  quantity: number;
  notes?: string;
  inventory?: InventoryReference;
};
