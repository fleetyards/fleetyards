/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { Shop } from '../models/Shop';
import type { ShopCommodity } from '../models/ShopCommodity';
import type { ShopCommodityOrderQuery } from '../models/ShopCommodityOrderQuery';
import type { ShopCommodityQuery } from '../models/ShopCommodityQuery';
import type { ShopQuery } from '../models/ShopQuery';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ShopsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Shop Commodity list
     * @returns ShopCommodity successful
     * @throws ApiError
     */
    public shopCommodities({
        slug,
        stationSlug,
        page = '1',
        perPage = '30',
        search,
        query,
        order,
        cacheId,
    }: {
        slug: string,
        stationSlug: string,
        page?: string,
        perPage?: string,
        search?: string,
        query?: ShopCommodityQuery,
        order?: ShopCommodityOrderQuery,
        cacheId?: string,
    }): CancelablePromise<Array<ShopCommodity>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{stationSlug}/shops/{slug}/commodities',
            path: {
                'slug': slug,
                'stationSlug': stationSlug,
            },
            query: {
                'page': page,
                'perPage': perPage,
                'search': search,
                'query': query,
                'order': order,
                'cacheId': cacheId,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * @deprecated
     * Shop types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public deprecateDshopsTypes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/shops/shop-types',
        });
    }

    /**
     * Shops list
     * @returns Shop successful
     * @throws ApiError
     */
    public shops({
        page = '1',
        perPage = '30',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: ShopQuery,
        cacheId?: string,
    }): CancelablePromise<Array<Shop>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/shops',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }

    /**
     * Shop Detail
     * @returns Shop successful
     * @throws ApiError
     */
    public shop({
        stationSlug,
        slug,
    }: {
        /**
         * Station slug
         */
        stationSlug: string,
        /**
         * Shop slug
         */
        slug: string,
    }): CancelablePromise<Shop> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{stationSlug}/shops/{slug}',
            path: {
                'stationSlug': stationSlug,
                'slug': slug,
            },
            errors: {
                404: `not found`,
            },
        });
    }

}
