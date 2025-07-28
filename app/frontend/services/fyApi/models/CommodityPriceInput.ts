/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type CommodityPriceInput = {
    commodityItemId: string;
    commodityItemType: string;
    path: CommodityPriceInput.path;
    shopId: string;
    timeRange?: string;
};
export namespace CommodityPriceInput {
    export enum path {
        BUY = 'buy',
        SELL = 'sell',
        RENTAL = 'rental',
    }
}

