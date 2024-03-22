/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BarChartStats } from '../models/BarChartStats';
import type { FleetMembersStats } from '../models/FleetMembersStats';
import type { FleetMembersStatsPublic } from '../models/FleetMembersStatsPublic';
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
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<FleetMembersStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/stats/members',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }
    /**
     * Fleet Stats Model Counts
     * @returns FleetModelCountsStats successful
     * @throws ApiError
     */
    public fleetModelCounts({
        fleetSlug,
        q,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<FleetModelCountsStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/stats/model-counts',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/stats/models-by-classification',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/stats/models-by-manufacturer',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/stats/models-by-production-status',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/stats/models-by-size',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<Array<BarChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/stats/vehicles-by-model',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<FleetVehiclesStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/stats/vehicles',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }
    /**
     * Public Fleet Members Stats
     * @returns FleetMembersStatsPublic successful
     * @throws ApiError
     */
    public publicFleetMembersStats({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<FleetMembersStatsPublic> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/fleets/{fleetSlug}/stats/members',
            path: {
                'fleetSlug': fleetSlug,
            },
            errors: {
                404: `not found`,
            },
        });
    }
    /**
     * Public Fleet Vehicles Stats
     * @returns FleetVehiclesStats successful
     * @throws ApiError
     */
    public publicFleetVehiclesStats({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<FleetVehiclesStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/fleets/{fleetSlug}/stats/vehicles',
            path: {
                'fleetSlug': fleetSlug,
            },
            errors: {
                404: `not found`,
            },
        });
    }
}
