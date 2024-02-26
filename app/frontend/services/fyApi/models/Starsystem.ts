/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CelestialObject } from './CelestialObject';
import type { MediaImage } from './MediaImage';
export type Starsystem = {
    name: string;
    slug: string;
    danger?: string;
    description?: string;
    economy?: string;
    locationLabel?: string;
    mapX?: string;
    mapY?: string;
    population?: string;
    size?: string;
    status?: string;
    type?: string;
    media: {
        storeImage?: MediaImage;
    };
    celestialObjects?: Array<CelestialObject>;
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

