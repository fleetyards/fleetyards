type Commodity = {
  id: string
}

type CommoditiesFilter = {
  nameCont: string
}

interface CommodityParams extends CollectionParams {
  filters: CommoditiesFilter
}
