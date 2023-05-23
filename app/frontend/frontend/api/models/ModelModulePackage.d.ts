type ModelModulePackagesFilter = {
  nameCont: string;
};

interface ModelModulePackageParams extends CollectionParams {
  filters: ModelModulesFilter;
}

type ModelModulePackage = {
  id: string;
  media: {
    storeImage?: FyMediaImage;
    fleetchartImage?: string;
    angledView?: FyMediaViewImage;
    frontView?: FyMediaViewImage;
    sideView?: FyMediaViewImage;
    topView?: FyMediaViewImage;
    angledViewColored?: FyMediaViewImage;
    frontViewColored?: FyMediaViewImage;
    sideViewColored?: FyMediaViewImage;
    topViewColored?: FyMediaViewImage;
  };
};
