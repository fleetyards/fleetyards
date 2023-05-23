type Station = {
  id: string;
  name: string;
  slug: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type StationsFilter = {
  nameCont: string;
};

interface StationParams extends CollectionParams {
  filters: StationsFilter;
}
