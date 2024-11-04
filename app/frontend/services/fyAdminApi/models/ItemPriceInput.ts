/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ItemPriceItemTypeEnum } from './ItemPriceItemTypeEnum';
import type { ItemPriceTypeEnum } from './ItemPriceTypeEnum';
export type ItemPriceInput = {
    itemId?: string;
    itemType?: ItemPriceItemTypeEnum;
    price?: number;
    priceType?: ItemPriceTypeEnum;
    location?: string;
    locationUrl?: string;
};

