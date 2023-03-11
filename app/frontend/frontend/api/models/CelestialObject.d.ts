type TCelestialObject = {
  id: string;
  slug: string;
  name: string;
  starsystem: TStarsystem;
  parent?: TCelestialObject;
  type: string;
  subType: string;
  starsystem: Starsystem;
  description: string;
  habitable: boolean;
  fairchanceact: boolean;
  population: number;
  economy: string;
  danger: string;
  locationLabel: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TCelestialObjectsFilter = {
  nameCont: string;
};

type TCelestialObjectParams = TCollectionParams<TCelestialObjectsFilter>;
