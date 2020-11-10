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
}

type FilterGroupItem = {
  value: any
  name: string
}
