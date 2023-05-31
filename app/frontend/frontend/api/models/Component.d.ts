type TComponent = {
  id: string;
  manufacturer: TManufacturer;
  name: string;
  slug: string;
  size: number;
  typeLabel: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TComponentsFilter = {
  nameCont: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TComponentParams = TCollectionParams<TComponentsFilter>;
