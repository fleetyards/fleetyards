export type ZoomData = {
  x: number;
  y: number;
  scale: number;
};

export interface ShipListState {
  detailsVisible: boolean;
  gridView: boolean;
  filterVisible: boolean;
}

// `extra` is an item RSI lists without a kind, under a pledge's "Also
// Contains". The server sorts it into hangar flair or FPS equipment.
export type RSIHangarItemKind =
  "ship" | "component" | "skin" | "upgrade" | "flair" | "equipment" | "extra";

export type RSIHangarItem = {
  id: string;
  name: string;
  image?: string;
  customName?: string;
  type: RSIHangarItemKind;
  pledgeName?: string;
  // In USD, what melting the whole pledge would return.
  pledgeValue?: number;
  pledgeItemCount?: number;
  pledgeCreatedOn?: string;
  meltable?: boolean;
};
