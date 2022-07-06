type ShopCommodity = {
  id: string
}

type ShopCommoditiesFilter = {
  nameCont: string
}

interface ShopCommodityParams extends CollectionParams {
  filters: ShopCommoditiesFilter
  search: string
  stationSlug: string
  slug: string
}
