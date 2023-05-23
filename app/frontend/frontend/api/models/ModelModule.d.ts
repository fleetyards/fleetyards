type ModelModulesFilter = {
  nameCont: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

interface ModelModuleParams extends CollectionParams {
  filters: ModelModulesFilter;
}

type ModelModule = {
  id: string;
};
