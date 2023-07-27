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
    media?: {
        storeImage?: MediaImage;
    };
    createdAt: string;
    updatedAt: string;
};

