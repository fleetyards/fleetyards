/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { MediaImage } from './MediaImage';
import type { Model } from './Model';
import type { RoadmapItemChangeset } from './RoadmapItemChangeset';
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
    media: {
        storeImage?: MediaImage | null;
    };
    released: boolean;
    committed: boolean;
    active: boolean;
    createdAt: string;
    updatedAt: string;
    model?: Model;
    lastVersionChangedAt: string;
    lastVersionChangedAtLabel: string;
    lastVersion?: RoadmapItemChangeset;
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

