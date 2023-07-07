/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { ImageComplete } from '../models/ImageComplete';
import type { StationComplete } from '../models/StationComplete';
import type { StationMinimal } from '../models/StationMinimal';
import type { StationQuery } from '../models/StationQuery';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class StationsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Station types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public types(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/station-types',
        });
    }

    /**
     * Station Ship sizes
     * @returns FilterOption successful
     * @throws ApiError
     */
    public shipSizes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/ship-sizes',
        });
    }

    /**
     * Station classifications
     * @returns FilterOption successful
     * @throws ApiError
     */
    public classifications(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/classifications',
        });
    }

    /**
     * Stations list
     * @returns StationMinimal successful
     * @throws ApiError
     */
    public list({
        page,
        perPage,
        q,
    }: {
        page?: number,
        perPage?: string,
        q?: StationQuery,
    }): CancelablePromise<Array<StationMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
            },
        });
    }

    /**
     * Station Detail
     * @returns StationComplete successful
     * @throws ApiError
     */
    public get({
        slug,
    }: {
        /**
         * Station slug
         */
        slug: string,
    }): CancelablePromise<StationComplete> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{slug}',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not_found`,
            },
        });
    }

    /**
     * Station Images
     * @returns ImageComplete successful
     * @throws ApiError
     */
    public images({
        slug,
    }: {
        /**
         * Station slug
         */
        slug: string,
    }): CancelablePromise<Array<ImageComplete>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{slug}/images',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not_found`,
            },
        });
    }

}
