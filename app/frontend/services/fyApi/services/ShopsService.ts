/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { ShopMinimal } from '../models/ShopMinimal';
import type { ShopQuery } from '../models/ShopQuery';
import type { Shops } from '../models/Shops';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ShopsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Shop types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public types(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/shops/shop-types',
        });
    }

    /**
     * Shops list
     * @returns Shops successful
     * @throws ApiError
     */
    public list({
        page,
        perPage,
        q,
        cacheId,
    }: {
        page?: number,
        perPage?: string,
        q?: ShopQuery,
        cacheId?: string,
    }): CancelablePromise<Shops> {
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
     * @returns ShopMinimal successful
     * @throws ApiError
     */
    public get({
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
    }): CancelablePromise<ShopMinimal> {
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
