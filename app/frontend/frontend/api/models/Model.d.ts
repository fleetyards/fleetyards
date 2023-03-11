type TModel = {
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
  manufacturer: TManufacturer;
  fleetchartLength: number;
  isGroundVehicle: boolean;
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
    storeImageMedium: string;
    storeImageLarge: string;
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
  cargo: number;
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

type TModelsFilter = {
  nameCont?: string;
};

type TModelParams = TCollectionParams<TModelsFilter>;

type TModelLoaner = {
  id: string;
  slug: string;
};

type TModelUpgrade = {
  id: string;
};
