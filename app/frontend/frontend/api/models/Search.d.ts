interface SearchResult extends Model, Station, Shop {
  resultType: string
}

type SearchFilter = {
  search: string
}

interface SearchParams extends CollectionParams {
  filters: SearchFilter
}
