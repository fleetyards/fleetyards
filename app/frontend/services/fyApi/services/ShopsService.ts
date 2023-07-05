/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ShopsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list shops
     * @returns any successful
     * @throws ApiError
     */
    public getShops(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/shops',
        });
    }

    /**
     * show shop
     * @returns any successful
     * @throws ApiError
     */
    public getStationsShops({
        stationSlug,
        slug,
    }: {
        /**
         * station_slug
         */
        stationSlug: string,
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{station_slug}/shops/{slug}',
            path: {
                'station_slug': stationSlug,
                'slug': slug,
            },
        });
    }

    /**
     * shop_types shop
     * @returns any successful
     * @throws ApiError
     */
    public getShopsShopTypes(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/shops/shop-types',
        });
    }

}
