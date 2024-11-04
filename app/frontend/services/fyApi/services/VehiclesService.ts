/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Check } from '../models/Check';
import type { CheckInput } from '../models/CheckInput';
import type { FilterOption } from '../models/FilterOption';
import type { Vehicle } from '../models/Vehicle';
import type { VehicleBulkDestroyInput } from '../models/VehicleBulkDestroyInput';
import type { VehicleBulkUpdateInput } from '../models/VehicleBulkUpdateInput';
import type { VehicleCreateInput } from '../models/VehicleCreateInput';
import type { VehicleUpdateInput } from '../models/VehicleUpdateInput';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class VehiclesService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Update multiple vehicles
     * @returns void
     * @throws ApiError
     */
    public vehicleUpdateBulk({
        requestBody,
    }: {
        requestBody: VehicleBulkUpdateInput,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/vehicles/bulk',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Destroy multiple Vehicles
     * @returns void
     * @throws ApiError
     */
    public vehicleDestroyBulk({
        requestBody,
    }: {
        requestBody: VehicleBulkDestroyInput,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/vehicles/destroy-bulk',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Check Vehicle Serial
     * @returns Check successful
     * @throws ApiError
     */
    public vehicleCheckSerial({
        requestBody,
    }: {
        requestBody: CheckInput,
    }): CancelablePromise<Check> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/vehicles/check-serial',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Create new Vehicle
     * @returns Vehicle successful
     * @throws ApiError
     */
    public vehicleCreate({
        requestBody,
    }: {
        requestBody: VehicleCreateInput,
    }): CancelablePromise<Vehicle> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/vehicles',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Delete all ingame bought Vehicles
     * @returns void
     * @throws ApiError
     */
    public destroyAllIngame(): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/vehicles/destroy-all-ingame',
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Delete Vehicle
     * @returns Vehicle successful
     * @throws ApiError
     */
    public vehicleDestroy({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<Vehicle> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/vehicles/{id}',
            path: {
                'id': id,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
    /**
     * Update Vehicle
     * @returns Vehicle successful
     * @throws ApiError
     */
    public vehicleUpdate({
        id,
        requestBody,
    }: {
        /**
         * id
         */
        id: string,
        requestBody: VehicleUpdateInput,
    }): CancelablePromise<Vehicle> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/vehicles/{id}',
            path: {
                'id': id,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
    /**
     * Bought Via Filters
     * @returns FilterOption successful
     * @throws ApiError
     */
    public boughtViaFilters(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/filters/bought-via',
        });
    }
}
