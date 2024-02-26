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
import type { StationClassificationEnum } from './StationClassificationEnum';
import type { StationSizeEnum } from './StationSizeEnum';
import type { StationTypeEnum } from './StationTypeEnum';
export type Station = {
    name: string;
    slug: string;
    cargoHub: boolean;
    type: StationTypeEnum;
    typeLabel: string;
    size: StationSizeEnum;
    sizeLabel: string;
    classification: StationClassificationEnum;
    classificationLabel: string;
    description?: string;
    dockCounts?: Array<DockCount>;
    habitable: boolean;
    habitationCounts?: Array<HabitationCount>;
    hasImages: boolean;
    locationLabel?: string;
    location?: string;
    media: {
        backgroundImage?: string;
        storeImage?: MediaImage;
    };
    refinery: boolean;
    shopListLabel?: string;
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
    backgroundImage?: string;
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

