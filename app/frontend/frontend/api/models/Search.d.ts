interface TSearchResult
  extends TModel,
    TStation,
    TShop,
    TCelestialObject,
    TStarsystem {
  resultType: string;
}

type TSearchFilter = {
  search: string;
};

type TSearchParams = TCollectionParams<TSearchFilter>;
