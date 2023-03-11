type TComponentsFilter = {
  nameCont: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TComponentParams = TCollectionParams<TComponentsFilter>;

type TComponent = {
  id: string;
};
