type CommodityPrice = {
  id?: string
  error: any
}

type CommodityPriceForm = {
  price: number
  path: string
  timeRange?: string
  commodityItemSlug: string
  commodityItemType: string
  shopId: string
}
