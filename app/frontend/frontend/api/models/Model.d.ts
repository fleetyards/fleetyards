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
  fleetchartLength: number;
  isGroundVehicle: boolean;
  hasPaints: boolean;
  metrics: {
    size: string;
    sizeLabel: string;
    length: number;
    lengthLabel: string;
    beam: number;
    beamLabel: string;
    height: number;
    heightLabel: string;
    isGroundVehicle: boolean;
    mass: number;
    massLabel: string;
    cargo: number;
    cargoLabel: string;
    hydrogenFuelTankSize: number;
    quantumFuelTankSize: number;
  };
  crew: {
    min: number;
    minLabel: string;
    max: number;
    maxLabel: string;
  };
  speeds: {
    scmSpeed: number;
    maxSpeed: number;
    groundMaxSpeed: number;
    groundReverseSpeed: number;
    groundAcceleration: number;
    groundDecceleration: number;
    scmSpeedAcceleration: number;
    scmSpeedDecceleration: number;
    maxSpeedAcceleration: number;
    maxSpeedDecceleration: number;
    pitch: number;
    yaw: number;
    roll: number;
  };
  media: {
    storeImage?: FyMediaImage;
    fleetchartImage?: string;
    angledView?: FyMediaViewImage;
    frontView?: FyMediaViewImage;
    sideView?: FyMediaViewImage;
    topView?: FyMediaViewImage;
    angledViewColored?: FyMediaViewImage;
    frontViewColored?: FyMediaViewImage;
    sideViewColored?: FyMediaViewImage;
    topViewColored?: FyMediaViewImage;
  };
  shipRole: ShipRole;
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
  hardpoints: ModelHardpoint[];
};

type ModelsFilter = {
  nameCont?: string;
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
