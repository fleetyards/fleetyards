type TFleet = {
  id: string;
  fid: string;
  name: string;
  slug: string;
  logo: string;
  description: string;
  myFleet: boolean;
  publicFleet: boolean;
  myRole: string;
};

type TFleetForm = {
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

interface TFleetVehicleParams extends TCollectionParams<TVehiclesFilter> {
  slug: string;
  grouped: boolean;
  perPage: "all" | number;
}

type TFleetVehicleStats = {
  total: number;
  classifications: TClassificationMetrics;
  metrics: TVehicleMetrics;
};

type TFleetModelCounts = {
  modelCounts: {
    [key: string]: number;
  };
};
