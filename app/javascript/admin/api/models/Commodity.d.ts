type Commodity = {
  id: string
}

type AdminCommodityFilter = {
  nameCont: string
}

interface AdminCommodityParams extends CollectionParams {
  filters: AdminCommodityFilter
}
