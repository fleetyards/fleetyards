/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { MediaImage } from './MediaImage';
import type { Model } from './Model';
export type ModelUpgrade = {
    id: string;
    name: string;
    description?: string;
    pledgePrice?: number;
    media: {
        storeImage?: MediaImage;
    };
    model: Model;
    createdAt: string;
    updatedAt: string;
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
};

