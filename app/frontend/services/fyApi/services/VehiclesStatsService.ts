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
    public deprecateDgetVehiclesQuickStats(): CancelablePromise<any> {
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
    public deprecateDgetVehiclesStatsModelsBySize(): CancelablePromise<any> {
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
    public deprecateDgetVehiclesStatsModelsByProductionStatus(): CancelablePromise<any> {
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
    public deprecateDgetVehiclesStatsModelsByManufacturer(): CancelablePromise<any> {
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
    public deprecateDgetVehiclesStatsModelsByClassification(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/stats/models-by-classification',
        });
    }

}
