/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ItemPrice } from './ItemPrice';
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
export type ModelModule = {
    id: string;
    name: string;
    availability: {
        boughtAt: Array<ItemPrice>;
        soldAt: Array<ItemPrice>;
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

