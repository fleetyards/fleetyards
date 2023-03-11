type TModelModulePackage = {
  id: string;
};

type TModelModulePackagesFilter = {
  nameCont: string;
};

interface TModelModulePackageParams extends TCollectionParams {
  filters: TModelModulesFilter;
}

type TModelModulePackage = {
  id: string;
  media: {
    storeImage?: TMediaImage;
    fleetchartImage?: string;
    angledView?: TMediaViewImage;
    frontView?: TMediaViewImage;
    sideView?: TMediaViewImage;
    topView?: TMediaViewImage;
    angledViewColored?: TMediaViewImage;
    frontViewColored?: TMediaViewImage;
    sideViewColored?: TMediaViewImage;
    topViewColored?: TMediaViewImage;
  };
};
