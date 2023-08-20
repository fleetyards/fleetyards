/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Commodity } from '../models/Commodity';
import type { CommodityQuery } from '../models/CommodityQuery';
import type { FilterOption } from '../models/FilterOption';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class CommoditiesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * @deprecated
     * Commodity Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public deprecateDcommodityTypes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/commodities/types',
        });
    }

    /**
     * Commodities list
     * @returns Commodity successful
     * @throws ApiError
     */
    public commodities({
        page = '1',
        perPage = '50',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: CommodityQuery,
        cacheId?: string,
    }): CancelablePromise<Array<Commodity>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/commodities',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }

}
