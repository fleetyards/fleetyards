interface SearchResult
  extends Model,
    Station,
    Shop,
    CelestialObject,
    Starsystem {
  resultType: string;
}

type SearchFilter = {
  search?: string;
};

interface SearchParams extends CollectionParams {
  filters: SearchFilter;
}
