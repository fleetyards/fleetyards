type AdminShopCommodity = {
  id: string
}

type AdminShopCommodityForm = {
  id: string
  commodtyItemId: string
  commodtyItemType: string
}

interface AdminShopCommodityParams extends CollectionParams {
  shopId: string
}
