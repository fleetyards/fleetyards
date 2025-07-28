/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Commodities } from '../models/Commodities';
import type { CommodityQuery } from '../models/CommodityQuery';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class CommotitiesService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Commodities list
     * Get a List of Commodities
     * @returns Commodities successful
     * @throws ApiError
     */
    public commodities({
        page = '1',
        perPage = '30',
        s,
        q,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: CommodityQuery,
    }): CancelablePromise<Commodities> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/commodities',
            query: {
                'page': page,
                'perPage': perPage,
                's': s,
                'q': q,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
