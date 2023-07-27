/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Commodity } from './Commodity';
import type { CommodityTypeEnum } from './CommodityTypeEnum';
import type { Component } from './Component';
import type { ComponentClassEnum } from './ComponentClassEnum';
import type { Equipment } from './Equipment';
import type { EquipmentTypeEnum } from './EquipmentTypeEnum';
import type { MediaImage } from './MediaImage';
import type { Model } from './Model';
import type { ModelClassificationEnum } from './ModelClassificationEnum';
import type { ModelModule } from './ModelModule';
import type { ModelPaint } from './ModelPaint';
import type { Shop } from './Shop';
import type { ShopCommodityCategoryEnum } from './ShopCommodityCategoryEnum';
import type { ShopCommodityItemTypeEnum } from './ShopCommodityItemTypeEnum';

export type ShopCommodityMinimal = {
    id: string;
    name: string;
    slug: string;
    description?: string | null;
    media?: {
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
    locationLabel?: string | null;
    confirmed: boolean;
    commodityItemType: ShopCommodityItemTypeEnum;
    commodityItemId: string;
    shop: Shop;
    item?: (Model | Component | Commodity | Equipment | ModelModule | ModelPaint);
    createdAt: string;
    updatedAt: string;
};

