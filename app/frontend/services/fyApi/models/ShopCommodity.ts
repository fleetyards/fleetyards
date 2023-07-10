/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { Shop } from './Shop';

export type ShopCommodity = {
    id: string;
    name: string;
    slug: string;
    description?: string | null;
    media: {
        storeImage?: MediaImage | null;
    };
    category?: string | null;
    subCategory?: string | null;
    subCategoryLabel?: string | null;
    prices: {
        averageBuyPrice?: number | null;
        averageRentalPrice1Day?: number | null;
        averageRentalPrice30Days?: number | null;
        averageRentalPrice3Days?: number | null;
        averageRentalPrice7Days?: number | null;
        averageSellPrice?: number | null;
        buyPrice?: number | null;
        rentalPrice1Day?: number | null;
        rentalPrice30Days?: number | null;
        rentalPrice3Days?: number | null;
        rentalPrice7Days?: number | null;
        sellPrice?: number | null;
    };
    pricePerUnit: boolean;
    locationLabel?: string | null;
    confirmed: boolean;
    commodityItemType: string;
    commodityItemId: string;
    shop: Shop;
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

