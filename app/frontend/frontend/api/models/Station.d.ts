type TStation = {
  id: string;
  name: string;
  slug: string;
  celestialObject: TCelestialObject;
  media: {
    storeImage?: TMediaImage;
  };
};

type TStationsFilter = {
  nameCont: string;
};

type TStationParams = TCollectionParams<TStationsFilter>;
