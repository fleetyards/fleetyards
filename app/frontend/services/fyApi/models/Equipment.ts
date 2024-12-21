/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';
export type Equipment = {
    id: string;
    name: string;
    slug: string;
    availability: {
        listedAt: Array<ShopCommodity>;
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    backpackCompatibility?: string;
    coreCompatibility?: string;
    damageReduction?: string;
    description?: string;
    extras?: string;
    grade?: string;
    itemType?: string;
    itemTypeLabel?: string;
    manufacturer?: Manufacturer;
    media: {
        storeImage?: MediaImage;
    };
    range?: string;
    rateOfFire?: string;
    size?: string;
    slot?: string;
    slotLabel?: string;
    storage?: string;
    temperatureRating?: string;
    type?: string;
    typeLabel?: string;
    volume?: string;
    weaponClass?: string;
    weaponClassLabel?: string;
    createdAt: string;
    updatedAt: string;
    /**
     * @deprecated
     */
    storeImage?: string;
    /**
     * @deprecated
     */
    storeImageIsFallback?: boolean;
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
};

