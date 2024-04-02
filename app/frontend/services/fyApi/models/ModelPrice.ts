/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ModelPriceTimeRangeEnum } from './ModelPriceTimeRangeEnum';
import type { ModelPriceTypeEnum } from './ModelPriceTypeEnum';
export type ModelPrice = {
    id: string;
    price: number;
    timeRange?: ModelPriceTimeRangeEnum;
    priceType: ModelPriceTypeEnum;
    location: string;
    locationUrl?: string;
    createdAt: string;
    updatedAt: string;
};

