type TCommodity = {
  id: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TCommoditiesFilter = {
  nameCont: string;
};

type TCommodityParams = TCollectionParams<TCommoditiesFilter>;
