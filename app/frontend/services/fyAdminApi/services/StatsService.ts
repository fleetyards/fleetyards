/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BarChartStats } from '../models/BarChartStats';
import type { Stats } from '../models/Stats';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class StatsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Stats most viewed Pages
     * @returns BarChartStats successful
     * @throws ApiError
     */
    public mostViewedPages(): CancelablePromise<Array<BarChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/most-viewed-pages',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Stats Registrations per Month
     * @returns BarChartStats successful
     * @throws ApiError
     */
    public registrationsPerMonth(): CancelablePromise<Array<BarChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/registrations-per-month',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Stats
     * @returns Stats successful
     * @throws ApiError
     */
    public stats(): CancelablePromise<Stats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/quick-stats',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Stats Visits per Day
     * @returns BarChartStats successful
     * @throws ApiError
     */
    public visitsPerDay(): CancelablePromise<Array<BarChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/visits-per-day',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Stats Visits per Month
     * @returns BarChartStats successful
     * @throws ApiError
     */
    public visitsPerMonth(): CancelablePromise<Array<BarChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/visits-per-month',
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
