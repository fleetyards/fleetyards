/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BarChartStats } from '../models/BarChartStats';
import type { FleetMembersStats } from '../models/FleetMembersStats';
import type { FleetModelCountsStats } from '../models/FleetModelCountsStats';
import type { FleetVehicleQuery } from '../models/FleetVehicleQuery';
import type { FleetVehiclesStats } from '../models/FleetVehiclesStats';
import type { PieChartStats } from '../models/PieChartStats';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetStatsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Fleet Members Stats
     * @returns FleetMembersStats successful
     * @throws ApiError
     */
    public fleetMembersStats({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<FleetMembersStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/members',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * Fleet Stats Model Counts
     * @returns FleetModelCountsStats successful
     * @throws ApiError
     */
    public fleetModelCounts({
        slug,
        q,
    }: {
        /**
         * slug
         */
        slug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<FleetModelCountsStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/model-counts',
            path: {
                'slug': slug,
            },
            query: {
                'q': q,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

    /**
     * Fleet Stats - Models by Classification
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public fleetModelsByClassification({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/models-by-classification',
            path: {
                'slug': slug,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Fleet Stats - Models by Manufacturer
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public fleetModelsByManufacturer({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/models-by-manufacturer',
            path: {
                'slug': slug,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Fleet Stats - Models by Production Status
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public fleetModelsByProductionStatus({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/models-by-production-status',
            path: {
                'slug': slug,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Fleet Stats - Models by Size
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public fleetModelsBySize({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/models-by-size',
            path: {
                'slug': slug,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Fleet Stats - Vehicles by Model
     * @returns BarChartStats successful
     * @throws ApiError
     */
    public fleetVehiclesByModel({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<Array<BarChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/vehicles-by-model',
            path: {
                'slug': slug,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Fleet Vehicles Stats
     * @returns FleetVehiclesStats successful
     * @throws ApiError
     */
    public fleetVehiclesStats({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<FleetVehiclesStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/stats/vehicles',
            path: {
                'slug': slug,
            },
        });
    }

}
