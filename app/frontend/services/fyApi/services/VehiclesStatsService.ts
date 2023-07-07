/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class VehiclesStatsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * @deprecated
     * quick_stats vehicle
     * @returns any successful
     * @throws ApiError
     */
    public quickStats(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/quick-stats',
        });
    }

    /**
     * @deprecated
     * models_by_size vehicle
     * @returns any successful
     * @throws ApiError
     */
    public statsModelsBySize(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-size',
        });
    }

    /**
     * @deprecated
     * models_by_production_status vehicle
     * @returns any successful
     * @throws ApiError
     */
    public statsModelsByProductionStatus(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-production-status',
        });
    }

    /**
     * @deprecated
     * models_by_manufacturer vehicle
     * @returns any successful
     * @throws ApiError
     */
    public statsModelsByManufacturer(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-manufacturer',
        });
    }

    /**
     * @deprecated
     * models_by_classification vehicle
     * @returns any successful
     * @throws ApiError
     */
    public statsModelsByClassification(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-classification',
        });
    }

}
