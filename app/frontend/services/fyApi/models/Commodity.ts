/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';

export type Commodity = {
    id: string;
    name: string;
    slug: string;
    type?: string | null;
    typeLabel?: string | null;
    availability: {
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    media: {
        storeImage?: MediaImage | null;
    };
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

