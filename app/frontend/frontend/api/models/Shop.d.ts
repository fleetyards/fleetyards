type TShop = {
  id: string;
  slug: string;
  name: string;
  station: TStation;
  celestialObject: TCelestialObject;
  buying: boolean;
  selling: boolean;
  rental: boolean;
  name: string;
  slug: string;
  stationSlug: string;
  station: TStation;
  description: string;
  location: string;
  media: {
    storeImage?: TMediaImage;
  };
};

type TShopsFilter = {
  nameCont: string;
};

interface TShopParams extends TCollectionParams<TShopsFilter> {
  stationSlug?: string;
  slug?: string;
}
