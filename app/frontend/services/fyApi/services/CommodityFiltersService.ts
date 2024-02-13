/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class CommodityFiltersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Commodity Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public commodityTypes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/filters/commodities/types',
        });
    }
}
