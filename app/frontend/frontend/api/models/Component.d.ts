type TComponentsFilter = {
  nameCont: string;
  manufacturer: TManufacturer;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TComponentParams = TCollectionParams<TComponentsFilter>;

type TComponent = {
  id: string;
};
