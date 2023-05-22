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
  storeImageMedium: string;
  storeImageSmall: string;
  angledView: string;
  angledViewMedium: string;
  angledViewLarge: string;
  angledViewHeight: number;
  angledViewWidth: number;
  frontView: string;
  frontViewMedium: string;
  frontViewLarge: string;
  frontViewHeight: number;
  frontViewWidth: number;
  topView: string;
  topViewMedium: string;
  topViewLarge: string;
  topViewHeight: number;
  topViewWidth: number;
  sideView: string;
  sideViewMedium: string;
  sideViewLarge: string;
  sideViewHeight: number;
  sideViewWidth: number;
  angledViewColored: string;
  angledViewColoredMedium: string;
  angledViewColoredLarge: string;
  angledViewColoredHeight: number;
  angledViewColoredWidth: number;
  frontViewColored: string;
  frontViewColoredMedium: string;
  frontViewColoredLarge: string;
  frontViewColoredHeight: number;
  frontViewColoredWidth: number;
  topViewColored: string;
  topViewColoredMedium: string;
  topViewColoredLarge: string;
  topViewColoredHeight: number;
  topViewColoredWidth: number;
  sideViewColored: string;
  sideViewColoredMedium: string;
  sideViewColoredLarge: string;
  sideViewColoredHeight: number;
  sideViewColoredWidth: number;
};
