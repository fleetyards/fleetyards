type Model = {
  id: string;
  slug: string;
  name: string;
  rsiName: string;
  description: string;
  focus: string;
  productionNote: string;
  productionStatus: string;
  classification: string;
  classificationLabel: string;
  manufacturer: Manufacturer;
  storeImageSmall: string;
  storeImageMedium: string;
  storeImageLarge: string;
  fleetchartImage: string;
  fleetchartLength: number;
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
  length: number;
  beam: number;
  height: number;
  mass: number;
  cargo: number;
  minCrew: number;
  maxCrew: number;
  sizeLabel: string;
  hasModules: boolean;
  hasUpgrades: boolean;
  rsiId: string;
  rsiName: string;
  salesPageUrl: string;
  storeUrl: string;
  onSale: boolean;
  price: number;
  pledgePrice: number;
  lastPledgePrice: number;
  rentalAt: Shop[];
  soldAt: Shop[];
  afterburnerSpeed: number;
  scmSpeed: number;
  groundSpeed: number;
  afterburnerGroundSpeed: number;
  hasVideos: boolean;
  hasImages: boolean;
  brochure: string;
  holo: string;
  lastUpdatedAt: string;
  lastUpdatedAtLabel: string;
  count?: number;
};

type ModelsFilter = {
  nameCont: string;
};

interface ModelParams extends CollectionParams {
  filters: ModelsFilter;
}

type ModelLoaner = {
  id: string;
  slug: string;
};

type ModelUpgrade = {
  id: string;
};
