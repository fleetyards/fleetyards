/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';

export type ModelUpgrade = {
    id: string;
    name: string | null;
    description?: string | null;
    pledgePrice?: number | null;
    media: {
        storeImage?: MediaImage | null;
    };
    createdAt: string;
    updatedAt: string;
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
};

