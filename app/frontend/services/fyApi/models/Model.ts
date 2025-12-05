/* generated using openapi-typescript-codegen -- do not edit */
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
    scIdentifier?: string;
    name: string;
    slug: string;
    availability: {
        listedAt: Array<ShopCommodity>;
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
        rentalAt: Array<ShopCommodity>;
    };
    brochure?: string;
    classification?: string;
    classificationLabel?: string;
    adiMap: boolean;
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
    /**
     * @deprecated
     */
    holoColored?: boolean;
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
    };
    onSale: boolean;
    pledgePrice?: number;
    pledgePriceLabel?: string;
    price?: number;
    priceLabel?: string;
    productionNote?: string;
    productionStatus?: string;
    rsiId?: number;
    rsiName?: string;
    rsiSlug?: string;
    speeds: {
        groundAcceleration?: number;
        groundDecceleration?: number;
        groundMaxSpeed?: number;
        groundReverseSpeed?: number;
        maxSpeed?: number;
        maxSpeedAcceleration?: number;
        maxSpeedDecceleration?: number;
        pitch?: number;
        roll?: number;
        scmSpeed?: number;
        scmSpeedAcceleration?: number;
        scmSpeedDecceleration?: number;
        yaw?: number;
    };
    createdAt: string;
    updatedAt: string;
    /**
     * @deprecated
     */
    afterburnerGroundSpeed?: number;
    /**
     * @deprecated
     */
    afterburnerSpeed?: number;
    /**
     * @deprecated
     */
    angledView?: string;
    /**
     * @deprecated
     */
    angledViewHeight?: number;
    /**
     * @deprecated
     */
    angledViewLarge?: string;
    /**
     * @deprecated
     */
    angledViewMedium?: string;
    /**
     * @deprecated
     */
    angledViewSmall?: string;
    /**
     * @deprecated
     */
    angledViewWidth?: number;
    /**
     * @deprecated
     */
    angledViewXlarge?: string;
    /**
     * @deprecated
     */
    beam?: number;
    /**
     * @deprecated
     */
    beamLabel?: string;
    /**
     * @deprecated
     */
    cargo?: number;
    /**
     * @deprecated
     */
    cargoLabel?: string;
    /**
     * @deprecated
     */
    fleetchartImage?: string;
    /**
     * @deprecated
     */
    fleetchartLength?: number;
    /**
     * @deprecated
     */
    groundSpeed?: number;
    /**
     * @deprecated
     */
    height?: number;
    /**
     * @deprecated
     */
    heightLabel?: string;
    /**
     * @deprecated
     */
    hydrogenFuelTankSize?: number;
    /**
     * @deprecated
     */
    length?: number;
    /**
     * @deprecated
     */
    lengthLabel?: string;
    /**
     * @deprecated
     */
    mass?: number;
    /**
     * @deprecated
     */
    massLabel?: number;
    /**
     * @deprecated
     */
    maxCrew?: number;
    /**
     * @deprecated
     */
    maxCrewLabel?: string;
    /**
     * @deprecated
     */
    minCrew?: number;
    /**
     * @deprecated
     */
    minCrewLabel?: string;
    /**
     * @deprecated
     */
    pitchMax?: number;
    /**
     * @deprecated
     */
    quantumFuelTankSize?: number;
    /**
     * @deprecated
     */
    rollMax?: number;
    /**
     * @deprecated
     */
    salesPageUrl?: string;
    /**
     * @deprecated
     */
    scmSpeed?: number;
    /**
     * @deprecated
     */
    sideView?: string;
    /**
     * @deprecated
     */
    sideViewHeight?: number;
    /**
     * @deprecated
     */
    sideViewLarge?: string;
    /**
     * @deprecated
     */
    sideViewMedium?: string;
    /**
     * @deprecated
     */
    sideViewSmall?: string;
    /**
     * @deprecated
     */
    sideViewWidth?: number;
    /**
     * @deprecated
     */
    sideViewXlarge?: string;
    /**
     * @deprecated
     */
    size?: string;
    /**
     * @deprecated
     */
    sizeLabel?: string;
    /**
     * @deprecated
     */
    storeImage?: string;
    /**
     * @deprecated
     */
    storeImageLarge?: string;
    /**
     * @deprecated
     */
    storeImageMedium?: string;
    /**
     * @deprecated
     */
    storeImageSmall?: string;
    /**
     * @deprecated
     */
    storeUrl?: string;
    /**
     * @deprecated
     */
    topView?: string;
    /**
     * @deprecated
     */
    topViewHeight?: number;
    /**
     * @deprecated
     */
    topViewLarge?: string;
    /**
     * @deprecated
     */
    topViewMedium?: string;
    /**
     * @deprecated
     */
    topViewSmall?: string;
    /**
     * @deprecated
     */
    topViewWidth?: number;
    /**
     * @deprecated
     */
    topViewXlarge?: string;
    /**
     * @deprecated
     */
    xaxisAcceleration?: number;
    /**
     * @deprecated
     */
    yawMax?: number;
    /**
     * @deprecated
     */
    yaxisAcceleration?: number;
    /**
     * @deprecated
     */
    zaxisAcceleration?: number;
};

