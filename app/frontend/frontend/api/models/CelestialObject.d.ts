type CelestialObject = {
  id: string;
  slug: string;
  name: string;
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

type CelestialObjectsFilter = {
  nameCont: string;
};

interface CelestialObjectParams extends CollectionParams {
  filters: CelestialObjectsFilter;
}
