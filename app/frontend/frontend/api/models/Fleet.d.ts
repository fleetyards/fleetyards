type Fleet = {
  id: string;
  fid: string;
  name: string;
  slug: string;
  logo: string;
  description: string;
  myFleet: boolean;
  publicFleet: boolean;
  myRole: "member" | "officer" | "admin";
};

type FleetForm = {
  fid: string;
  rsiSid: string;
  name: string;
  discord: string;
  ts: string;
  homepage: string;
  twitch: string;
  youtube: string;
  guilded: string;
  removeLogo: boolean;
};

interface FleetVehicleParams extends CollectionParams {
  slug: string;
  filters: VehiclesFilter;
  grouped: boolean;
  perPage: "all" | number;
}

type FleetVehicleStats = {
  total: number;
  classifications: ClassificationMetrics;
  metrics: VehicleMetrics;
};

type FleetModelCounts = {
  modelCounts: {
    [key: string]: number;
  };
};
