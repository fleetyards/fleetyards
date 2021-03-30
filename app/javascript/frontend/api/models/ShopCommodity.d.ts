type ShopCommodity = {
  id: string
}

type ShopCommoditiesFilter = {
  nameCont: string
}

interface ShopCommodityParams extends CollectionParams {
  filters: ShopCommoditiesFilter
  stationSlug: string
  slug: string
}
