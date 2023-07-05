/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Manufacturer } from './Manufacturer';
import type { ShopCommodity } from './ShopCommodity';

export type EquipmentMinimal = {
    id: string;
    name: string;
    slug: string;
    availability: {
        boughtAt: Array<ShopCommodity>;
        listedAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    backpackCompatibility?: string | null;
    coreCompatibility?: string | null;
    damageReduction?: string | null;
    description?: string;
    extras?: string | null;
    grade?: string | null;
    itemType?: string | null;
    itemTypeLabel?: string | null;
    manufacturer?: Manufacturer | null;
    media: any;
    range?: string | null;
    rateOfFire?: string | null;
    size?: string | null;
    slot?: string | null;
    slotLabel?: string | null;
    storage?: string | null;
    temperatureRating?: string | null;
    type?: string | null;
    typeLabel?: string | null;
    volume?: string | null;
    weaponClass?: string | null;
    weaponClassLabel?: string | null;
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
    createdAt: string;
    updatedAt: string;
};

