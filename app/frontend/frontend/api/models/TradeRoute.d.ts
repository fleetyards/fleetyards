type TradeRoute = {
  sellPrice: string
  buyPrice: string
}

type TradeRoutesFilter = {
  originIn: string[]
}

interface TradeRouteParams extends CollectionParams {
  filters: TradeRoutesFilter
}
