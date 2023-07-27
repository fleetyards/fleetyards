/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { CommodityTypeEnum } from './CommodityTypeEnum';
import type { ComponentClassEnum } from './ComponentClassEnum';
import type { EquipmentTypeEnum } from './EquipmentTypeEnum';
import type { MediaImage } from './MediaImage';
import type { ModelClassificationEnum } from './ModelClassificationEnum';
import type { Shop } from './Shop';
import type { ShopCommodityCategoryEnum } from './ShopCommodityCategoryEnum';
import type { ShopCommodityItemTypeEnum } from './ShopCommodityItemTypeEnum';

export type ShopCommodity = {
    id: string;
    name: string;
    slug: string;
    description?: string | null;
    media: {
        storeImage?: MediaImage;
    };
    category?: ShopCommodityCategoryEnum;
    subCategory?: (ModelClassificationEnum | ComponentClassEnum | EquipmentTypeEnum | CommodityTypeEnum);
    subCategoryLabel?: string;
    prices: {
        averageBuyPrice?: number;
        averageRentalPrice1Day?: number;
        averageRentalPrice30Days?: number;
        averageRentalPrice3Days?: number;
        averageRentalPrice7Days?: number;
        averageSellPrice?: number;
        buyPrice?: number;
        rentalPrice1Day?: number;
        rentalPrice30Days?: number;
        rentalPrice3Days?: number;
        rentalPrice7Days?: number;
        sellPrice?: number;
        pricePerUnit: boolean;
    };
    locationLabel?: string;
    confirmed: boolean;
    commodityItemType: ShopCommodityItemTypeEnum;
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

