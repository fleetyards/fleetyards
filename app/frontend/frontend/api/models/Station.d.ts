type Station = {
  id: string;
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
