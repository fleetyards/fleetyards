type ModelPaintsFilter = {
  nameCont: string;
};

interface ModelPaintParams extends CollectionParams {
  filters: ModelPaintsFilter;
}

type ModelPaint = {
  id: string;
  name: string;
  rsiId: string;
  rsiName: string;
  media: {
    storeImage: FyMediaImage;
    fleetchartImage: string;
    angledView: FyMediaViewImage;
    frontView: FyMediaViewImage;
    sideView: FyMediaViewImage;
    topView: FyMediaViewImage;
  };
};
