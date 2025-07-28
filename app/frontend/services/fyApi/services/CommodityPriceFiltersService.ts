/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class CommodityPriceFiltersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Commodity Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public commodityPriceTimeRanges(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/filters/commodity-prices/time-ranges',
        });
    }
}
