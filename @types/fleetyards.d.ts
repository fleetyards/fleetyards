interface KeyValuePair {
  [key: string]: string | null
}

type FilterGroupItem = {
  value: any
  name: string
}

type CartItemSoldAt = {
  id: string
  price: number
  shopName: string
  shopSlug: string
  stationName: string
  stationSlug: string
}

type CartItem = {
  id: string
  type: string
  name: string
  bestSoldAt: CartItemSoldAt
  soldAt: CartItemSoldAt[]
  amount: number
}
