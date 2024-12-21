/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CommodityTypeEnum } from './CommodityTypeEnum';
import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';
export type Commodity = {
    id: string;
    name: string;
    slug: string;
    type?: CommodityTypeEnum;
    typeLabel?: string;
    availability: {
        listedAt: Array<ShopCommodity>;
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    media: {
        storeImage?: MediaImage;
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

