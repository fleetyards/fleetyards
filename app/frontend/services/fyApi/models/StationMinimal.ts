/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { CelestialObject } from './CelestialObject';
import type { DockCount } from './DockCount';
import type { HabitationCount } from './HabitationCount';
import type { MediaImage } from './MediaImage';

export type StationMinimal = {
    name: string;
    slug: string;
    cargoHub: boolean;
    classificationLabel?: string | null;
    classification?: string | null;
    description?: string | null;
    dockCounts?: Array<DockCount>;
    habitable: boolean;
    habitationCounts?: Array<HabitationCount>;
    hasImages: boolean;
    locationLabel?: string | null;
    location?: string | null;
    media: {
        backgroundImage?: string | null;
        storeImage?: MediaImage | null;
    };
    refinery: boolean;
    shopListLabel?: string | null;
    typeLabel?: string | null;
    type?: string | null;
    /**
     * @deprecated
     */
    backgroundImage?: string | null;
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
    celestialObject: CelestialObject;
    createdAt: string;
    updatedAt: string;
};

