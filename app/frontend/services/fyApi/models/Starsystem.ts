/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { CelestialObject } from './CelestialObject';
import type { MediaImage } from './MediaImage';

export type Starsystem = {
    name: string;
    slug: string;
    danger?: string | null;
    description?: string | null;
    economy?: string | null;
    locationLabel?: string | null;
    mapX?: string | null;
    mapY?: string | null;
    population?: string | null;
    size?: string | null;
    status?: string | null;
    type?: string | null;
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

