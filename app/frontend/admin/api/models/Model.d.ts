type AdminModel = {
  id: string;
  name: string;
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

type AdminModelsFilter = {
  idEq?: string;
  idIn?: string[];
  nameCont?: string;
};

interface AdminAdminModelParams extends CollectionParams {
  filters: AdminModelsFilter;
}
