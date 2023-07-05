/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CommodityMinimal } from '../models/CommodityMinimal';
import type { CommodityPrice } from '../models/CommodityPrice';
import type { FilterOption } from '../models/FilterOption';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class CommoditiesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list commodities
     * Get a List of Commodities
     * @returns CommodityMinimal successful
     * @throws ApiError
     */
    public getCommodities(): CancelablePromise<Array<CommodityMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/commodities',
        });
    }

    /**
     * commodity_types commodity
     * Get a List of all Commodity Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public getCommoditiesTypes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/commodities/types',
        });
    }

    /**
     * create commodity_price
     * Create new CommodityPrice
     * @returns CommodityPrice successful
     * @throws ApiError
     */
    public postCommodityPrices({
        requestBody,
    }: {
        requestBody: {
            $ref?: any;
        },
    }): CancelablePromise<CommodityPrice> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/commodity-prices',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `invalid data`,
                401: `unauthorized`,
            },
        });
    }

    /**
     * time_ranges commodity_price
     * Get a List of all Commodity Price TimeRanges
     * @returns FilterOption successful
     * @throws ApiError
     */
    public getCommodityPricesTimeRanges(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/commodity-prices/time-ranges',
        });
    }

}
