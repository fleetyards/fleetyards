type Pagination = {
  currentPage: number
  totalPages: number
}

type CollectionParams = {
  page?: number
  cacheId?: string
}

type CollectionResponse<T> = {
  data: T[] | null
  error: string | null
}

type RecordResponse<T> = {
  data?: T | null
  error?: string | null
}
