type TModelPaint = {
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

type TModelPaintsFilter = {
  nameCont: string;
};

type TModelPaintParams = TCollectionParams<TModelPaintsFilter>;
