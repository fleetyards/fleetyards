type TShopCommodity = {
  id: string;
};

type TShopCommoditiesFilter = {
  nameCont: string;
  subCategoryIn: string[];
};

interface TShopCommodityParams
  extends TCollectionParams<TShopCommoditiesFilter> {
  stationSlug: string;
  slug: string;
}

type TShopCommoditySubCategroy = {
  name: string;
  value: string;
  category: string;
};
