/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { Starsystem } from './Starsystem';

export type CelestialObject = {
    name: string;
    slug: string;
    designation: string;
    description?: string | null;
    type?: string | null;
    habitable?: boolean | null;
    fairchanceact?: boolean | null;
    subType?: string | null;
    size?: string | null;
    danger?: number | null;
    economy?: number | null;
    population?: number | null;
    locationLabel?: string | null;
    media?: {
        storeImage?: MediaImage | null;
    };
    starsystem: Starsystem;
    parent?: CelestialObject;
    moons?: Array<CelestialObject>;
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

