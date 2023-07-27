/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ShopCommodityMinimal } from '../models/ShopCommodityMinimal';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ShopCommoditiesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Shop Commodity Destroy
     * @returns ShopCommodityMinimal successful
     * @throws ApiError
     */
    public destroyShopCommodity({
        id,
    }: {
        /**
         * Shop Commodity ID
         */
        id: string,
    }): CancelablePromise<ShopCommodityMinimal> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/shop-commodities/{id}',
            path: {
                'id': id,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

}
