/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class StatsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * quick_stats stat
     * @returns any successful
     * @throws ApiError
     */
    public getStatsQuickStats(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/quick-stats',
        });
    }

    /**
     * models_per_month stat
     * @returns any successful
     * @throws ApiError
     */
    public getStatsModelsPerMonth(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-per-month',
        });
    }

    /**
     * models_by_size stat
     * @returns any successful
     * @throws ApiError
     */
    public getStatsModelsBySize(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-by-size',
        });
    }

    /**
     * models_by_production_status stat
     * @returns any successful
     * @throws ApiError
     */
    public getStatsModelsByProductionStatus(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-by-production-status',
        });
    }

    /**
     * models_by_manufacturer stat
     * @returns any successful
     * @throws ApiError
     */
    public getStatsModelsByManufacturer(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-by-manufacturer',
        });
    }

    /**
     * models_by_classification stat
     * @returns any successful
     * @throws ApiError
     */
    public getStatsModelsByClassification(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/models-by-classification',
        });
    }

    /**
     * components_by_class stat
     * @returns any successful
     * @throws ApiError
     */
    public getStatsComponentsByClass(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stats/components-by-class',
        });
    }

}
