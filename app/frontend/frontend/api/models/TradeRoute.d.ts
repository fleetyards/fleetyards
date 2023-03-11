type TTradeRoute = {
  id: string;
  sellPrice: string;
  buyPrice: string;
};

type TTradeRoutesFilter = {
  originIn: string[];
};

type TTradeRouteParams = TCollectionParams<TTradeRoutesFilter>;
