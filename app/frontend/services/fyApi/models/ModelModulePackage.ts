/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { MediaImage } from './MediaImage';
import type { ModelModule } from './ModelModule';
import type { ViewImage } from './ViewImage';
export type ModelModulePackage = {
    id: string;
    name: string;
    description?: string;
    pledgePrice?: number;
    modules: Array<ModelModule>;
    media: {
        angledView?: ViewImage;
        sideView?: ViewImage;
        storeImage?: MediaImage;
        topView?: ViewImage;
    };
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

