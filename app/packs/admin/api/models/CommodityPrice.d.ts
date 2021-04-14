type AdminCommodityPrice = {
  id: string
}

type AdminCommodityPriceForm = {
  id: string
  shopId: string
  shopCommodityId: string
  path: string
}

interface AdminCommodityPriceParams extends CollectionParams {
  shopId: string
  shopCommodityId: string
  path: string
}
