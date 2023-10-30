type CommodityPrice = {
  id?: string;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  error: any;
};

type CommodityPriceForm = {
  price: number;
  path: string;
  timeRange?: string;
  commodityItemSlug: string;
  commodityItemType: string;
  shopId: string;
};
