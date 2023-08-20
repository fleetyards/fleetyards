/* generated using openapi-typescript-codegen -- do no edit */
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
     * @deprecated
     * with_models manufacturer
     * @returns Manufacturers successful
     * @throws ApiError
     */
    public deprecateDgetManufacturersWithModels(): CancelablePromise<Manufacturers> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/manufacturers/with-models',
        });
    }

    /**
     * Manufacturers list
     * @returns Manufacturers successful
     * @throws ApiError
     */
    public manufacturers({
        page = '1',
        perPage = '30',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: ManufacturerQuery,
        cacheId?: string,
    }): CancelablePromise<Manufacturers> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/manufacturers',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }

}
