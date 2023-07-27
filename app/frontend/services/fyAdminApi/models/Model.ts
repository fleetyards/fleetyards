/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
import type { ModelLoaner } from './ModelLoaner';
import type { ShopCommodity } from './ShopCommodity';
import type { ViewImage } from './ViewImage';

export type Model = {
    id: string;
    scIdentifier?: string | null;
    name: string;
    slug: string;
    availability: {
        boughtAt: Array<ShopCommodity>;
        listedAt: Array<ShopCommodity>;
        rentalAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    brochure?: string | null;
    classification?: string | null;
    classificationLabel?: string | null;
    crew: {
        max?: number | null;
        maxLabel?: string | null;
        min?: number | null;
        minLabel?: string | null;
    };
    description?: string | null;
    erkulIdentifier?: string | null;
    focus?: string | null;
    hasImages: boolean;
    hasModules: boolean;
    hasPaints: boolean;
    hasUpgrades: boolean;
    hasVideos: boolean;
    holo?: string | null;
    /**
     * @deprecated
     */
    holoColored?: boolean | null;
    lastPledgePrice?: number | null;
    lastPledgePriceLabel?: string | null;
    lastUpdatedAt?: string | null;
    lastUpdatedAtLabel?: string | null;
    links: {
        salesPageUrl?: string | null;
        storeUrl?: string | null;
    };
    loaners: Array<ModelLoaner>;
    manufacturer?: Manufacturer;
    media?: {
        angledView?: ViewImage;
        angledViewColored?: ViewImage;
        fleetchartImage?: string | null;
        frontView?: ViewImage;
        frontViewColored?: ViewImage;
        sideView?: ViewImage;
        sideViewColored?: ViewImage;
        storeImage?: MediaImage;
        topView?: ViewImage;
        topViewColored?: ViewImage;
    };
    metrics: {
        beam?: number | null;
        beamLabel?: string | null;
        cargo?: number | null;
        cargoLabel?: string | null;
        fleetchartLength?: number | null;
        height?: number | null;
        heightLabel?: string | null;
        hydrogenFuelTankSize?: number | null;
        isGroundVehicle?: boolean;
        length?: number | null;
        lengthLabel?: string | null;
        mass?: number | null;
        massLabel?: string | null;
        quantumFuelTankSize?: number | null;
        size?: string | null;
        sizeLabel?: string | null;
    };
    onSale: boolean;
    pledgePrice?: number | null;
    pledgePriceLabel?: string | null;
    price?: number | null;
    priceLabel?: string | null;
    productionNote?: string | null;
    productionStatus?: string | null;
    rsiId?: number | null;
    rsiName?: string | null;
    rsiSlug?: string | null;
    speeds: {
        groundAcceleration?: number | null;
        groundDecceleration?: number | null;
        groundMaxSpeed?: number | null;
        groundReverseSpeed?: number | null;
        maxSpeed?: number | null;
        maxSpeedAcceleration?: number | null;
        maxSpeedDecceleration?: number | null;
        pitch?: number | null;
        roll?: number | null;
        scmSpeed?: number | null;
        scmSpeedAcceleration?: number | null;
        scmSpeedDecceleration?: number | null;
        yaw?: number | null;
    };
};

