/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { ModelMinimal } from './ModelMinimal';

export type RoadmapItem = {
    id: string;
    name: string;
    release: string;
    releaseDescription?: string;
    rsiReleaseId: number;
    description: string;
    body: string;
    rsiCategoryId: number;
    image: string;
    media?: {
        storeImage?: MediaImage | null;
    };
    released: boolean;
    committed: boolean;
    active: boolean;
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
    model?: ModelMinimal;
    lastVersionChangedAt: string;
    lastVersionChangedAtLabel: string;
    lastVersion?: string;
    createdAt: string;
    updatedAt: string;
};

