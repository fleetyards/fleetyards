export type ZoomData = {
  x: number;
  y: number;
  scale: number;
};

export enum TableViewColsEnum {
  MANUFACTURER_NAME = "manufacturer_name",
  LENGTH = "length",
  BEAM = "beam",
  HEIGHT = "height",
  MASS = "mass",
  CARGO = "cargo",
  CREW = "crew",
  PRICE = "price",
  PLEDGE_PRICE = "pledge_price",
}

export interface ShipListState {
  detailsVisible: boolean;
  gridView: boolean;
  filterVisible: boolean;
  tableViewCols: TableViewColsEnum[];
}

export type RSIHangarItemKind = "ship" | "component" | "skin" | "upgrade";

export type RSIHangarItem = {
  id: string;
  name: string;
  image?: string;
  customName?: string;
  type: RSIHangarItemKind;
};
