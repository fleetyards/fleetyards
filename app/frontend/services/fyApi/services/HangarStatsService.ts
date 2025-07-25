/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarQuery } from '../models/HangarQuery';
import type { HangarStats } from '../models/HangarStats';
import type { PieChartStats } from '../models/PieChartStats';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class HangarStatsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Hangar Stats - Models by Classification
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public hangarModelsByClassification(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar/stats/models-by-classification',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Hangar Stats - Models by Manufacturer
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public hangarModelsByManufacturer(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar/stats/models-by-manufacturer',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Hangar Stats - Models by Production Status
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public hangarModelsByProductionStatus(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar/stats/models-by-production-status',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Hangar Stats - Models by Size
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public hangarModelsBySize(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar/stats/models-by-size',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Your Hangar Stats
     * @returns HangarStats successful
     * @throws ApiError
     */
    public hangarStats({
        q,
    }: {
        q?: HangarQuery,
    }): CancelablePromise<HangarStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar/stats',
            query: {
                'q': q,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
