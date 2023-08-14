/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { CelestialObject } from './CelestialObject';
import type { Dock } from './Dock';
import type { DockCount } from './DockCount';
import type { Habitation } from './Habitation';
import type { HabitationCount } from './HabitationCount';
import type { ImageMinimal } from './ImageMinimal';
import type { MediaImage } from './MediaImage';
import type { ShopMinimal } from './ShopMinimal';
import type { StarsystemMinimal } from './StarsystemMinimal';

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
    starsystem?: StarsystemMinimal;
    shops?: Array<ShopMinimal>;
    docks?: Array<Dock>;
    habitations?: Array<Habitation>;
    images?: Array<ImageMinimal>;
};

