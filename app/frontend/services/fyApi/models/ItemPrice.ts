/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ItemPriceTimeRangeEnum } from './ItemPriceTimeRangeEnum';
import type { ItemPriceTypeEnum } from './ItemPriceTypeEnum';
export type ItemPrice = {
    id: string;
    price: number;
    timeRange?: ItemPriceTimeRangeEnum;
    priceType: ItemPriceTypeEnum;
    location: string;
    locationUrl?: string;
    createdAt: string;
    updatedAt: string;
};

