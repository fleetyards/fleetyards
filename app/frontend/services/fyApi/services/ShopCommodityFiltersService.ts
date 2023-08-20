/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CommodityItemType } from '../models/CommodityItemType';
import type { FilterOption } from '../models/FilterOption';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ShopCommodityFiltersService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Shop Commodity Commodity Type Options
     * @returns CommodityItemType successful
     * @throws ApiError
     */
    public commodityTypeOptions(): CancelablePromise<Array<CommodityItemType>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/filters/shop-commodities/commodity-type-options',
        });
    }

    /**
     * Shop Commodity Sub Categories
     * @returns FilterOption successful
     * @throws ApiError
     */
    public shopCommoditySubCategories(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/filters/shop-commodities/sub-categories',
        });
    }

}
