/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { Images } from '../models/Images';
import type { Station } from '../models/Station';
import type { StationQuery } from '../models/StationQuery';
import type { Stations } from '../models/Stations';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class StationsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Station types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public stationsTypes(): CancelablePromise<Array<FilterOption>> {
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
    public stationsShipSizes(): CancelablePromise<Array<FilterOption>> {
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
    public stationsClassifications(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/classifications',
        });
    }

    /**
     * Stations list
     * @returns Stations successful
     * @throws ApiError
     */
    public stations({
        page = '1',
        perPage = '10',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: StationQuery,
        cacheId?: string,
    }): CancelablePromise<Stations> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }

    /**
     * Station Detail
     * @returns Station successful
     * @throws ApiError
     */
    public station({
        slug,
    }: {
        /**
         * Station slug
         */
        slug: string,
    }): CancelablePromise<Station> {
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
     * @returns Images successful
     * @throws ApiError
     */
    public stationImages({
        slug,
        page = '1',
        perPage = '30',
    }: {
        /**
         * Station slug
         */
        slug: string,
        page?: string,
        perPage?: string,
    }): CancelablePromise<Images> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{slug}/images',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                404: `not_found`,
            },
        });
    }

}
