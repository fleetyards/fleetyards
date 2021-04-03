interface KeyValuePair {
  [key: string]: string | null
}

type ApiResponseMeta = {
  currentPage: number
  totalPages: number
}

interface Window {
  APP_VERSION: string
  STORE_VERSION: string
  APP_CODENAME: string
  API_ENDPOINT: string
  DATA_PREFILL: KeyValuePair
  ON_SUBDOMAIN: boolean
  FRONTEND_ENDPOINT: string
  SERVICE_WORKER_URL: string
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
