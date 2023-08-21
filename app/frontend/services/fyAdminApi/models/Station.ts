/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { CelestialObject } from './CelestialObject';
import type { Dock } from './Dock';
import type { DockCount } from './DockCount';
import type { Habitation } from './Habitation';
import type { HabitationCount } from './HabitationCount';
import type { MediaImage } from './MediaImage';
import type { Shop } from './Shop';
import type { Starsystem } from './Starsystem';
import type { StationTypeEnum } from './StationTypeEnum';

export type Station = {
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
    media?: {
        backgroundImage?: string | null;
        storeImage?: MediaImage;
    };
    refinery: boolean;
    shopListLabel?: string | null;
    typeLabel?: string | null;
    type?: StationTypeEnum;
    celestialObject: CelestialObject;
    starsystem?: Starsystem;
    shops?: Array<Shop>;
    docks?: Array<Dock>;
    habitations?: Array<Habitation>;
    createdAt: string;
    updatedAt: string;
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
    id: string;
};

