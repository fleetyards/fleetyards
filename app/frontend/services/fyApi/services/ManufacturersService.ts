/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ManufacturerMinimal } from '../models/ManufacturerMinimal';
import type { ManufacturerQuery } from '../models/ManufacturerQuery';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ManufacturersService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * @deprecated
     * with_models manufacturer
     * @returns ManufacturerMinimal successful
     * @throws ApiError
     */
    public getManufacturersWithModels(): CancelablePromise<Array<ManufacturerMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/manufacturers/with-models',
        });
    }

    /**
     * Manufacturers list
     * @returns ManufacturerMinimal successful
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
        q?: ManufacturerQuery,
        cacheId?: string,
    }): CancelablePromise<Array<ManufacturerMinimal>> {
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
