/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { ModelModule } from './ModelModule';
import type { ViewImage } from './ViewImage';

export type ModelModulePackageMinimal = {
    id: string;
    name: string | null;
    description?: string | null;
    modules?: Array<ModelModule>;
    pledgePrice?: number | null;
    media?: {
        angledView?: ViewImage | null;
        sideView?: ViewImage | null;
        storeImage?: MediaImage | null;
        topView?: ViewImage | null;
    };
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
    createdAt: string;
    updatedAt: string;
};

