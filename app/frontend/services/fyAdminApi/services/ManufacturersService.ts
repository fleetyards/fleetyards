/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ManufacturerQuery } from '../models/ManufacturerQuery';
import type { Manufacturers } from '../models/Manufacturers';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ManufacturersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Manufacturers list
     * @returns Manufacturers successful
     * @throws ApiError
     */
    public manufacturers({
        page = '1',
        perPage = '30',
        s,
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: ManufacturerQuery,
        cacheId?: string,
    }): CancelablePromise<Manufacturers> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/manufacturers',
            query: {
                'page': page,
                'perPage': perPage,
                's': s,
                'q': q,
                'cacheId': cacheId,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
