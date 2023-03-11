type TVehicle = {
  id: string;
  name: string;
  model: TModel;
  loaner: boolean;
  public: boolean;
  wanted: boolean;
  flagship: boolean;
  saleNotify: boolean;
  modelModuleIds: string[];
  modelUpgradeIds: string[];
  paint: TModelPaint;
  boughtVia: string;
  boughtViaLabel: string;
  username?: string;
  storeImageMedium: string;
  storeImageSmall: string;
  modulePackage: ModelModulePackage;
};

type TVehicleForm = {
  name?: string;
  wanted?: boolean;
  modelId?: string;
  flagship?: boolean;
  public?: boolean;
  saleNotify?: boolean;
  nameVisible?: boolean;
  hangarGroupIds?: string[];
  modelPaintId?: string;
};

type TVehiclesFilter = {
  modelNameCont?: string;
  modelSlugIn?: string[];
};

type TVehicleParams = TCollectionParams<TVehiclesFilter>;

type TVehicleMetrics = {
  totalMoney: number;
  totalMinCrew: number;
  totalMaxCrew: number;
  totalCargo: number;
  totalCredits: number;
};

type TClassificationMetrics = {
  name: string;
  label: string;
  count: number;
};

type THangarGroupMetrics = {
  id: string;
  slug: string;
  count: number;
};

type TVehicleStats = {
  total: number;
  wishlistTotal: number;
  classifications: TClassificationMetrics;
  groups: THangarGroupMetrics[];
  metrics: TVehicleMetrics;
};

interface TPublicVehicleParams extends TCollectionParams<TVehiclesFilter> {
  username: string;
}

type TPublicVehicleStats = {
  total: number;
  classifications: TClassificationMetrics;
};
