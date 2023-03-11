type TShop = {
  id: string;
  shopName: string;
  shopSlug: string;
  stationName: string;
  stationSlug: string;
};

export type TShoppingCartItemType =
  | "Component"
  | "Commodity"
  | "Equipment"
  | "Model";

export type TShoppingCartItem = {
  id: string;
  type: TShoppingCartItemType;
  name: string;
  bestSoldAt: TShop;
  soldAt: TShop[];
  listedAt: TShop[];
  amount: number;
};
