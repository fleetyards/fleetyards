type TStarsystem = {
  id: string;
  slug: string;
  name: string;
  locationLabel: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TStarsystemFilter = {
  nameCont: string;
};

type TStarsystemParams = TCollectionParams<TStarsystemFilter>;
