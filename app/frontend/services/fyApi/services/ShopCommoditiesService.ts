/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ShopCommoditiesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list shop_commodities
     * @returns any successful
     * @throws ApiError
     */
    public getStationsShopsCommodities({
        stationSlug,
        shopSlug,
    }: {
        /**
         * station_slug
         */
        stationSlug: string,
        /**
         * shop_slug
         */
        shopSlug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{station_slug}/shops/{shop_slug}/commodities',
            path: {
                'station_slug': stationSlug,
                'shop_slug': shopSlug,
            },
        });
    }

    /**
     * commodity_item_types shop_commodity
     * @returns any successful
     * @throws ApiError
     */
    public getShopCommoditiesCommodityTypeOptions(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/shop-commodities/commodity-type-options',
        });
    }

    /**
     * sub_categories shop_commodity
     * @returns any successful
     * @throws ApiError
     */
    public getFiltersShopCommoditiesSubCategories(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/filters/shop-commodities/sub-categories',
        });
    }

}
