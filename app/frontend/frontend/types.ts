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

export type RSIHangarItemKind = "ship" | "component" | "skin" | "upgrade";

export type RSIHangarItem = {
  id: string;
  name: string;
  image?: string;
  customName?: string;
  type: RSIHangarItemKind;
};
