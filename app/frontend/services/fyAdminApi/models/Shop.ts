/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { ShopTypeEnum } from './ShopTypeEnum';
import type { StationShop } from './StationShop';

export type Shop = {
    id: string;
    name: string;
    slug: string;
    buying: boolean;
    location?: string | null;
    locationLabel: string;
    media?: {
        storeImage?: MediaImage;
    };
    refineryTerminal: boolean;
    rental: boolean;
    selling: boolean;
    station: StationShop;
    stationLabel: string;
    type: ShopTypeEnum;
    typeLabel: string;
    /**
     * @deprecated
     */
    storeImage?: string | null;
    /**
     * @deprecated
     */
    storeImageSmall?: string | null;
    /**
     * @deprecated
     */
    storeImageMedium?: string | null;
    /**
     * @deprecated
     */
    storeImageLarge?: string | null;
};

