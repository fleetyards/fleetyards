/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { Shop } from '../models/Shop';
import type { ShopMinimal } from '../models/ShopMinimal';
import type { ShopQuery } from '../models/ShopQuery';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ShopsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Shop types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public shopsTypes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/shops/shop-types',
        });
    }

    /**
     * Shops list
     * @returns ShopMinimal successful
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
    }): CancelablePromise<Array<ShopMinimal>> {
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
