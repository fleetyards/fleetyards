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
import type { ModelModule } from './ModelModule';
import type { ModelPaint } from './ModelPaint';
import type { Shop } from './Shop';
import type { ShopCommodityCategoryEnum } from './ShopCommodityCategoryEnum';
import type { ShopCommodityItemTypeEnum } from './ShopCommodityItemTypeEnum';
export type ShopCommodity = {
    id: string;
    name: string;
    slug: string;
    description?: string;
    media: {
        storeImage?: MediaImage;
    };
    category?: ShopCommodityCategoryEnum;
    subCategory?: (string | ComponentClassEnum | EquipmentTypeEnum | CommodityTypeEnum);
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
    item?: (Model | Component | Commodity | Equipment | ModelModule | ModelPaint);
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
    submitter?: {
        id: string;
        username: string;
    };
};

