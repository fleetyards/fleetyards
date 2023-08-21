/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { DockCount } from './DockCount';
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
import type { ModelLoaner } from './ModelLoaner';
import type { ShopCommodity } from './ShopCommodity';
import type { ViewImage } from './ViewImage';

export type ModelExtended = {
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
        self?: string;
        frontend?: string;
    };
    loaners: Array<ModelLoaner>;
    manufacturer?: Manufacturer | null;
    media: {
        angledView?: ViewImage | null;
        angledViewColored?: ViewImage | null;
        fleetchartImage?: string | null;
        frontView?: ViewImage | null;
        frontViewColored?: ViewImage | null;
        sideView?: ViewImage | null;
        sideViewColored?: ViewImage | null;
        storeImage?: MediaImage | null;
        topView?: ViewImage | null;
        topViewColored?: ViewImage | null;
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
    createdAt: string;
    updatedAt: string;
    /**
     * @deprecated
     */
    afterburnerGroundSpeed?: number | null;
    /**
     * @deprecated
     */
    afterburnerSpeed?: number | null;
    /**
     * @deprecated
     */
    angledView?: string | null;
    /**
     * @deprecated
     */
    angledViewHeight?: number | null;
    /**
     * @deprecated
     */
    angledViewLarge?: string | null;
    /**
     * @deprecated
     */
    angledViewMedium?: string | null;
    /**
     * @deprecated
     */
    angledViewSmall?: string | null;
    /**
     * @deprecated
     */
    angledViewWidth?: number | null;
    /**
     * @deprecated
     */
    angledViewXlarge?: string | null;
    /**
     * @deprecated
     */
    beam?: number | null;
    /**
     * @deprecated
     */
    beamLabel?: string | null;
    /**
     * @deprecated
     */
    cargo?: number | null;
    /**
     * @deprecated
     */
    cargoLabel?: string | null;
    /**
     * @deprecated
     */
    fleetchartImage?: string | null;
    /**
     * @deprecated
     */
    fleetchartLength?: number | null;
    /**
     * @deprecated
     */
    groundSpeed?: number | null;
    /**
     * @deprecated
     */
    height?: number | null;
    /**
     * @deprecated
     */
    heightLabel?: string | null;
    /**
     * @deprecated
     */
    hydrogenFuelTankSize?: number | null;
    /**
     * @deprecated
     */
    length?: number | null;
    /**
     * @deprecated
     */
    lengthLabel?: string | null;
    /**
     * @deprecated
     */
    mass?: number | null;
    /**
     * @deprecated
     */
    massLabel?: number | null;
    /**
     * @deprecated
     */
    maxCrew?: number | null;
    /**
     * @deprecated
     */
    maxCrewLabel?: string | null;
    /**
     * @deprecated
     */
    minCrew?: number | null;
    /**
     * @deprecated
     */
    minCrewLabel?: string | null;
    /**
     * @deprecated
     */
    pitchMax?: number | null;
    /**
     * @deprecated
     */
    quantumFuelTankSize?: number | null;
    /**
     * @deprecated
     */
    rollMax?: number | null;
    /**
     * @deprecated
     */
    salesPageUrl?: string | null;
    /**
     * @deprecated
     */
    scmSpeed?: number | null;
    /**
     * @deprecated
     */
    sideView?: string | null;
    /**
     * @deprecated
     */
    sideViewHeight?: number | null;
    /**
     * @deprecated
     */
    sideViewLarge?: string | null;
    /**
     * @deprecated
     */
    sideViewMedium?: string | null;
    /**
     * @deprecated
     */
    sideViewSmall?: string | null;
    /**
     * @deprecated
     */
    sideViewWidth?: number | null;
    /**
     * @deprecated
     */
    sideViewXlarge?: string | null;
    /**
     * @deprecated
     */
    size?: string | null;
    /**
     * @deprecated
     */
    sizeLabel?: string | null;
    /**
     * @deprecated
     */
    storeImage?: string | null;
    /**
     * @deprecated
     */
    storeImageLarge?: string | null;
    /**
     * @deprecated
     */
    storeImageMedium?: string | null;
    /**
     * @deprecated
     */
    storeImageSmall?: string | null;
    /**
     * @deprecated
     */
    storeUrl?: string | null;
    /**
     * @deprecated
     */
    topView?: string | null;
    /**
     * @deprecated
     */
    topViewHeight?: number | null;
    /**
     * @deprecated
     */
    topViewLarge?: string | null;
    /**
     * @deprecated
     */
    topViewMedium?: string | null;
    /**
     * @deprecated
     */
    topViewSmall?: string | null;
    /**
     * @deprecated
     */
    topViewWidth?: number | null;
    /**
     * @deprecated
     */
    topViewXlarge?: string | null;
    /**
     * @deprecated
     */
    xaxisAcceleration?: number | null;
    /**
     * @deprecated
     */
    yawMax?: number | null;
    /**
     * @deprecated
     */
    yaxisAcceleration?: number | null;
    /**
     * @deprecated
     */
    zaxisAcceleration?: number | null;
    dockCounts: Array<DockCount>;
};

