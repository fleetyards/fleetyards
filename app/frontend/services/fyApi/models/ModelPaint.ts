/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';
import type { ViewImage } from './ViewImage';

export type ModelPaint = {
    id: string;
    name: string | null;
    slug: string | null;
    availability: {
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    description?: string | null;
    lastUpdatedAt?: string | null;
    lastUpdatedAtLabel?: string | null;
    media: {
        angledView?: ViewImage;
        fleetchartImage?: string | null;
        sideView?: ViewImage;
        storeImage?: MediaImage;
        topView?: ViewImage;
    };
    nameWithModel?: string | null;
    rsiId?: number | null;
    rsiName?: string | null;
    rsiSlug?: string | null;
    /**
     * @deprecated
     */
    angledView?: string | null;
    /**
     * @deprecated
     */
    angledViewHeight?: number | null;
    /**
     * @deprecated
     */
    angledViewLarge?: string | null;
    /**
     * @deprecated
     */
    angledViewMedium?: string | null;
    /**
     * @deprecated
     */
    angledViewSmall?: string | null;
    /**
     * @deprecated
     */
    angledViewWidth?: number | null;
    /**
     * @deprecated
     */
    angledViewXlarge?: string | null;
    /**
     * @deprecated
     */
    fleetchartImage?: string | null;
    hasStoreImage?: boolean | null;
    /**
     * @deprecated
     */
    sideView?: string | null;
    /**
     * @deprecated
     */
    sideViewHeight?: number | null;
    /**
     * @deprecated
     */
    sideViewLarge?: string | null;
    /**
     * @deprecated
     */
    sideViewMedium?: string | null;
    /**
     * @deprecated
     */
    sideViewSmall?: string | null;
    /**
     * @deprecated
     */
    sideViewWidth?: number | null;
    /**
     * @deprecated
     */
    sideViewXlarge?: string | null;
    /**
     * @deprecated
     */
    storeImage?: string | null;
    /**
     * @deprecated
     */
    storeImageLarge?: string | null;
    /**
     * @deprecated
     */
    storeImageMedium?: string | null;
    /**
     * @deprecated
     */
    storeImageSmall?: string | null;
    /**
     * @deprecated
     */
    topView?: string | null;
    /**
     * @deprecated
     */
    topViewHeight?: number | null;
    /**
     * @deprecated
     */
    topViewLarge?: string | null;
    /**
     * @deprecated
     */
    topViewMedium?: string | null;
    /**
     * @deprecated
     */
    topViewSmall?: string | null;
    /**
     * @deprecated
     */
    topViewWidth?: number | null;
    /**
     * @deprecated
     */
    topViewXlarge?: string | null;
};

