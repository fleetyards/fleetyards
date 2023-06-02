type ModelPaintFilters = {
  modelSlugEq?: string;
  nameCont?: string;
  idIn?: string[];
  idEq?: string;
};

interface ModelPaintParams extends CollectionParams {
  filters: ModelPaintFilters;
}

type ModelPaint = {
  id: string;
  name: string;
  rsiId: string;
  rsiName: string;
  media: {
    storeImage?: FyMediaImage;
    fleetchartImage?: string;
    angledView?: FyMediaViewImage;
    frontView?: FyMediaViewImage;
    sideView?: FyMediaViewImage;
    topView?: FyMediaViewImage;
  };
};
