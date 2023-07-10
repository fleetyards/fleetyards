/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';

export type CommodityMinimal = {
    id: string;
    name: string;
    slug: string;
    availability: {
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    type?: string | null;
    typeLabel?: string | null;
    media: {
        storeImage?: MediaImage | null;
    };
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

