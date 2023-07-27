/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';

export type ModelUpgradeMinimal = {
    id: string;
    name: string | null;
    description?: string | null;
    media: {
        storeImage?: MediaImage;
    };
    pledgePrice?: number | null;
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
    createdAt: string;
    updatedAt: string;
};

