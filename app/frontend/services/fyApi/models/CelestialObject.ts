/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { StarsystemMinimal } from './StarsystemMinimal';

export type CelestialObject = {
    name: string;
    slug: string;
    designation: string;
    media?: {
        storeImage?: MediaImage | null;
    };
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
    starsystem: StarsystemMinimal | null;
    createdAt: string;
    updatedAt: string;
    parent?: CelestialObject | null;
    moons?: Array<CelestialObject>;
};

