type Starsystem = {
  id: string;
  slug: string;
  name: string;
  locationLabel: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type StarsystemFilter = {
  nameCont: string;
};

interface StarsystemParams extends CollectionParams {
  filters: StarsystemFilter;
}
