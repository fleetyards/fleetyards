/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ShopCommodity } from '../models/ShopCommodity';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ShopCommoditiesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Shop Commodity Destroy
     * @returns ShopCommodity successful
     * @throws ApiError
     */
    public destroyShopCommodity({
        id,
    }: {
        /**
         * Shop Commodity ID
         */
        id: string,
    }): CancelablePromise<ShopCommodity> {
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
