type TShopCommodity = {
  id: string;
  name: string;
  slug: string;
  category: string;
  item: TModel | TEquipment | TComponent;
};

type TShopCommodityFilters = {
  name?: string[];
  category?: string[];
  manufacturerSlug?: string[];
  subCategory?: string[];
  priceGteq?: number;
  priceLteq?: number;
};

interface TShopCommodityParams
  extends TCollectionParams<TShopCommodityFilters> {
  stationSlug: string;
  slug: string;
}

type TShopCommoditySubCategroy = {
  name: string;
  value: string;
  category: string;
};
