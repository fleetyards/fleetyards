/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetsStatsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * models_by_size fleet_stat
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsStatsModelsBySize({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/models-by-size',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * models_by_production_status fleet_stat
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsStatsModelsByProductionStatus({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/models-by-production-status',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * models_by_manufacturer fleet_stat
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsStatsModelsByManufacturer({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/models-by-manufacturer',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * models_by_classification fleet_stat
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsStatsModelsByClassification({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/models-by-classification',
            path: {
                'slug': slug,
            },
        });
    }

}
