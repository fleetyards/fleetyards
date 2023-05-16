type Model = {
  id: string;
  slug: string;
  name: string;
  rsiName: string;
  description: string;
  focus: string;
  productionNote: string;
  productionStatus: string;
  manufacturer: Manufacturer;
  storeImageSmall: string;
  storeImageMedium: string;
  storeImageLarge: string;
  fleetchartImage: string;
  fleetchartLength: number;
  angledViewMedium: string;
  angledViewLarge: string;
  frontViewMedium: string;
  frontViewLarge: string;
  topViewMedium: string;
  topViewLarge: string;
  sideViewMedium: string;
  sideViewLarge: string;
  length: number;
  hasModules: boolean;
  hasUpgrades: boolean;
  rsiId: string;
  rsiName: string;
  salesPageUrl: string;
  storeUrl: string;
  onSale: boolean;
  pledgePrice: number;
  hasVideos: boolean;
  hasImages: boolean;
  brochure: string;
  holo: string;
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
