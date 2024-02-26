/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CelestialObject } from './CelestialObject';
import type { MediaImage } from './MediaImage';
import type { ShopTypeEnum } from './ShopTypeEnum';
import type { StationShop } from './StationShop';
export type Shop = {
    id: string;
    name: string;
    slug: string;
    buying: boolean;
    location?: string;
    locationLabel: string;
    media: {
        storeImage?: MediaImage;
    };
    refineryTerminal: boolean;
    rental: boolean;
    selling: boolean;
    station: StationShop;
    stationLabel: string;
    type: ShopTypeEnum;
    typeLabel: string;
    celestialObject?: CelestialObject;
    createdAt: string;
    updatedAt: string;
    /**
     * @deprecated
     */
    storeImage?: string;
    /**
     * @deprecated
     */
    storeImageSmall?: string;
    /**
     * @deprecated
     */
    storeImageMedium?: string;
    /**
     * @deprecated
     */
    storeImageLarge?: string;
};

