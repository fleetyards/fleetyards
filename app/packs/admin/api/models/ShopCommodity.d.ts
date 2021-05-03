type AdminShopCommodity = {
  id: string
}

type AdminShopCommodityForm = {
  id: string
  commodtyItemId: string
  commodtyItemType: string
}

type AdminShopCommodityFilter = {
  componentItemTypeIn: string[]
}

interface AdminShopCommodityParams extends CollectionParams {
  filters?: AdminShopCommodityFilter
  shopId: string
}
