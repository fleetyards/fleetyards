/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { CelestialObject } from './CelestialObject';
import type { Dock } from './Dock';
import type { DockCount } from './DockCount';
import type { Habitation } from './Habitation';
import type { HabitationCount } from './HabitationCount';
import type { Image } from './Image';
import type { MediaImage } from './MediaImage';
import type { Shop } from './Shop';
import type { StarsystemMinimal } from './StarsystemMinimal';

export type Station = {
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
    media: {
        backgroundImage?: string | null;
        storeImage?: MediaImage | null;
    };
    refinery: boolean;
    shopListLabel?: string | null;
    typeLabel?: string | null;
    type?: string | null;
    createdAt: string;
    updatedAt: string;
    starsystem?: StarsystemMinimal;
    shops?: Array<Shop>;
    docks?: Array<Dock>;
    habitations?: Array<Habitation>;
    images?: Array<Image>;
};

