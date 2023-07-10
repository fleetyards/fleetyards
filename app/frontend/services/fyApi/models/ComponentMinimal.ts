/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';

export type ComponentMinimal = {
    id: string;
    name: string;
    slug: string;
    availability: {
        boughtAt: Array<ShopCommodity>;
        listedAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    class?: string | null;
    grade?: string | null;
    itemClass?: string | null;
    itemClassLabel?: string | null;
    manufacturer?: Manufacturer | null;
    media: {
        storeImage?: MediaImage | null;
    };
    size?: string | null;
    trackingSignal?: string | null;
    trackingSignalLabel?: string | null;
    type?: string | null;
    typeLabel?: string | null;
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

