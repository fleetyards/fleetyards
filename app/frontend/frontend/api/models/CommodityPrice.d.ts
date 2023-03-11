type TCommodityPrice = {
  id: string;
};

type TCommodityPriceForm = {
  price: number;
  path: string;
  timeRange?: string;
  commodityItemSlug: string;
  commodityItemType: string;
  shopId: string;
};
