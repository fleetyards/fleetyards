/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CargoHold } from './CargoHold';
import type { FuelTank } from './FuelTank';
import type { ItemPrice } from './ItemPrice';
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
import type { ModelLoaner } from './ModelLoaner';
import type { ModelProductionStatusEnum } from './ModelProductionStatusEnum';
import type { ViewImage } from './ViewImage';
export type Model = {
    id: string;
    scIdentifier?: string;
    name: string;
    slug: string;
    availability: {
        boughtAt: Array<ItemPrice>;
        soldAt: Array<ItemPrice>;
        rentalAt: Array<ItemPrice>;
    };
    brochure?: string;
    classification?: string;
    classificationLabel?: string;
    crew: {
        max?: number;
        maxLabel?: string;
        min?: number;
        minLabel?: string;
    };
    description?: string;
    erkulIdentifier?: string;
    focus?: string;
    hasImages: boolean;
    hasModules: boolean;
    hasPaints: boolean;
    hasUpgrades: boolean;
    hasVideos: boolean;
    holo?: string;
    lastPledgePrice?: number;
    lastPledgePriceLabel?: string;
    lastUpdatedAt?: string;
    lastUpdatedAtLabel?: string;
    links: {
        salesPageUrl?: string;
        storeUrl?: string;
    };
    loaners: Array<ModelLoaner>;
    manufacturer?: Manufacturer;
    media: {
        angledView?: ViewImage;
        angledViewColored?: ViewImage;
        fleetchartImage?: string;
        frontView?: ViewImage;
        frontViewColored?: ViewImage;
        sideView?: ViewImage;
        sideViewColored?: ViewImage;
        storeImage?: MediaImage;
        topView?: ViewImage;
        topViewColored?: ViewImage;
    };
    metrics: {
        beam?: number;
        beamLabel?: string;
        cargo?: number;
        cargoLabel?: string;
        fleetchartLength?: number;
        height?: number;
        heightLabel?: string;
        hydrogenFuelTankSize?: number;
        isGroundVehicle?: boolean;
        length?: number;
        lengthLabel?: string;
        mass?: number;
        massLabel?: string;
        quantumFuelTankSize?: number;
        size?: string;
        sizeLabel?: string;
        dockSize?: string;
    };
    cargoHolds?: Array<CargoHold>;
    hydrogenFuelTanks?: Array<FuelTank>;
    quantumFuelTanks?: Array<FuelTank>;
    onSale: boolean;
    pledgePrice?: number;
    pledgePriceLabel?: string;
    price?: number;
    priceLabel?: string;
    productionNote?: string;
    productionStatus?: ModelProductionStatusEnum;
    rsiId?: number;
    rsiName?: string;
    rsiSlug?: string;
    speeds: {
        groundAcceleration?: number;
        groundDecceleration?: number;
        groundMaxSpeed?: number;
        groundReverseSpeed?: number;
        maxSpeed?: number;
        pitch?: number;
        pitchBoosted?: number;
        roll?: number;
        rollBoosted?: number;
        scmSpeed?: number;
        scmSpeedBoosted?: number;
        reverseSpeedBoosted?: number;
        yaw?: number;
        yawBoosted?: number;
    };
    createdAt: string;
    updatedAt: string;
};

