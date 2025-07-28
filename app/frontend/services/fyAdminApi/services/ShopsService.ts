/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ShopCommodities } from '../models/ShopCommodities';
import type { ShopCommodityOrder } from '../models/ShopCommodityOrder';
import type { ShopCommodityQuery } from '../models/ShopCommodityQuery';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ShopsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Shop Commodities list
     * Get a List of Shop Commodities
     * @returns ShopCommodities successful
     * @throws ApiError
     */
    public shopCommodities({
        shopId,
        page = '1',
        perPage = '30',
        order,
        filters,
    }: {
        shopId: string,
        page?: string,
        perPage?: string,
        order?: ShopCommodityOrder,
        filters?: ShopCommodityQuery,
    }): CancelablePromise<ShopCommodities> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/shops/{shopId}/commodities',
            path: {
                'shopId': shopId,
            },
            query: {
                'page': page,
                'perPage': perPage,
                'order': order,
                'filters': filters,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
}
