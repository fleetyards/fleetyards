type TModelModule = {
  id: string;
};

type TModelModulesFilter = {
  nameCont: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TModelModuleParams = TCollectionParams<TModelModulesFilter>;
