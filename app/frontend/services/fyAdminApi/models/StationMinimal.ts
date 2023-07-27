/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { CelestialObject } from './CelestialObject';
import type { DockCount } from './DockCount';
import type { HabitationCount } from './HabitationCount';
import type { MediaImage } from './MediaImage';

export type StationMinimal = {
    id: string;
    name: string;
    slug: string;
    cargoHub: boolean;
    celestialObject: CelestialObject;
    classificationLabel?: string | null;
    classification?: string | null;
    description?: string | null;
    dockCounts?: Array<DockCount>;
    habitable: boolean;
    habitationCounts?: Array<HabitationCount>;
    hasImages: boolean;
    locationLabel?: string | null;
    location?: string | null;
    media?: {
        backgroundImage?: string | null;
        storeImage?: MediaImage;
    };
    refinery: boolean;
    shopListLabel?: string | null;
    typeLabel?: string | null;
    type?: string | null;
    createdAt: string;
    updatedAt: string;
};

