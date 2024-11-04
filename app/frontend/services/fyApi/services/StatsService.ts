/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BarChartStats } from '../models/BarChartStats';
import type { PieChartStats } from '../models/PieChartStats';
import type { Stats } from '../models/Stats';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class StatsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Stats Components by Class
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public componentsByClass(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/components-by-class',
        });
    }
    /**
     * Stats Models by Classification
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public modelsByClassification(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-by-classification',
        });
    }
    /**
     * Stats Models by Manufacturer
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public modelsByManufacturer(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-by-manufacturer',
        });
    }
    /**
     * Stats Models by Production-Status
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public modelsByProductionStatus(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-by-production-status',
        });
    }
    /**
     * Stats Models by Size
     * @returns PieChartStats successful
     * @throws ApiError
     */
    public modelsBySize(): CancelablePromise<Array<PieChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-by-size',
        });
    }
    /**
     * Stats Models per Month
     * @returns BarChartStats successful
     * @throws ApiError
     */
    public modelsPerMonth(): CancelablePromise<Array<BarChartStats>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-per-month',
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
        });
    }
}
