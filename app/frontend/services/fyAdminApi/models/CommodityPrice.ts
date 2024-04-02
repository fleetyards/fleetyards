/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ShopCommodity } from './ShopCommodity';
export type CommodityPrice = {
    id: string;
    price: number;
    timeRange?: string;
    confirmed: boolean;
    type: string;
    submitters: Array<string>;
    shopCommodity?: ShopCommodity;
    createdAt: string;
    updatedAt: string;
};

