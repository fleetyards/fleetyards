/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class VehiclesStatsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * quick_stats vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesQuickStats(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/quick-stats',
        });
    }

    /**
     * models_by_size vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesStatsModelsBySize(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-size',
        });
    }

    /**
     * models_by_production_status vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesStatsModelsByProductionStatus(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-production-status',
        });
    }

    /**
     * models_by_manufacturer vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesStatsModelsByManufacturer(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-manufacturer',
        });
    }

    /**
     * models_by_classification vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesStatsModelsByClassification(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-classification',
        });
    }

}
