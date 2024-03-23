/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';
export type ModelModule = {
    id: string;
    name: string;
    availability: {
        listedAt: Array<ShopCommodity>;
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    description?: string;
    media: {
        storeImage?: MediaImage;
    };
    pledgePrice?: number;
    productionStatus?: string;
    manufacturer?: Manufacturer;
    createdAt: string;
    updatedAt: string;
    /**
     * @deprecated
     */
    hasStoreImage?: boolean;
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
};

