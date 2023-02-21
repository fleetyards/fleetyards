type Vehicle = {
  id: string;
  name: string;
  model: Model;
  loaner: boolean;
  public: boolean;
  wanted: boolean;
  flagship: boolean;
  saleNotify: boolean;
  modelModuleIds: string[];
  modelUpgradeIds: string[];
  paint: ModelPaint;
};

type VehicleForm = {
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

type VehiclesFilter = {
  modelNameCont?: string;
  modelSlugIn?: string[];
};

interface VehicleParams extends CollectionParams {
  filters: VehiclesFilter;
}

interface PublicVehicleParams extends CollectionParams {
  username: string;
  filters: VehiclesFilter;
}

type VehicleMetrics = {
  totalMoney: number;
  totalMinCrew: number;
  totalMaxCrew: number;
  totalCargo: number;
};

type ClassificationMetrics = {
  name: string;
  label: string;
  count: number;
};

type HangarGroupMetrics = {
  id: string;
  slug: string;
  count: number;
};

type VehicleStats = {
  total: number;
  classifications: ClassificationMetrics;
  groups: HangarGroupMetrics[];
  metrics: VehicleMetrics;
};

type PublicVehicleStats = {
  total: number;
  classifications: ClassificationMetrics;
};
