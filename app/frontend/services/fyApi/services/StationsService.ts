/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class StationsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list stations
     * @returns any successful
     * @throws ApiError
     */
    public getStations(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations',
        });
    }

    /**
     * show station
     * @returns any successful
     * @throws ApiError
     */
    public getStations1({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{slug}',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * images station
     * @returns any successful
     * @throws ApiError
     */
    public getStationsImages({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/{slug}/images',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * ship_sizes station
     * @returns any successful
     * @throws ApiError
     */
    public getStationsShipSizes(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/ship-sizes',
        });
    }

    /**
     * station_types station
     * @returns any successful
     * @throws ApiError
     */
    public getStationsStationTypes(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/station-types',
        });
    }

    /**
     * classifications station
     * @returns any successful
     * @throws ApiError
     */
    public getStationsClassifications(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations/classifications',
        });
    }

}
