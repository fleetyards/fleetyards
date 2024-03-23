/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';
import type { ViewImage } from './ViewImage';
export type ModelPaint = {
    id: string;
    name: string;
    slug: string;
    description?: string;
    lastUpdatedAt?: string;
    lastUpdatedAtLabel?: string;
    availability: {
        listedAt: Array<ShopCommodity>;
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    media: {
        angledView?: ViewImage;
        fleetchartImage?: string;
        sideView?: ViewImage;
        storeImage?: MediaImage;
        topView?: ViewImage;
    };
    nameWithModel?: string;
    rsiId?: number;
    rsiName?: string;
    rsiSlug?: string;
    createdAt: string;
    updatedAt: string;
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
    fleetchartImage?: string;
    hasStoreImage?: boolean;
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
};

