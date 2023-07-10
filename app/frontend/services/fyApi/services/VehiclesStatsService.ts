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
     * Vehicle Quickstats -> use GET /hangar/stats
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
     * @deprecated
     * Vehicle Models by size -> use GET /hangar/stats/models-by-size
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
     * @deprecated
     * Vehicle Models by ProductionStatus -> use GET /hangar/stats/models-by-production-status
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
     * @deprecated
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
     * @deprecated
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
