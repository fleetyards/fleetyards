type Shop = {
  id: string;
  name: string;
  slug: string;
  stationSlug: string;
  station: Station;
  location: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type ShopsFilter = {
  nameCont: string;
};

interface ShopParams extends CollectionParams {
  filters?: ShopsFilter;
  stationSlug?: string;
  slug?: string;
}
