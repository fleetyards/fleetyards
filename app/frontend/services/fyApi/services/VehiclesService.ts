/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Hangar } from '../models/Hangar';
import type { HangarImportResult } from '../models/HangarImportResult';
import type { HangarQuery } from '../models/HangarQuery';
import type { VehicleBulkDestroyInput } from '../models/VehicleBulkDestroyInput';
import type { VehicleBulkUpdateInput } from '../models/VehicleBulkUpdateInput';
import type { VehicleCheckSerialInput } from '../models/VehicleCheckSerialInput';
import type { VehicleCheckSerialResponse } from '../models/VehicleCheckSerialResponse';
import type { VehicleCreateInput } from '../models/VehicleCreateInput';
import type { VehicleExport } from '../models/VehicleExport';
import type { VehicleMinimal } from '../models/VehicleMinimal';
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
    public updateBulk({
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
    public destroyBulk({
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
     * @returns VehicleCheckSerialResponse successful
     * @throws ApiError
     */
    public checkSerial({
        requestBody,
    }: {
        requestBody: VehicleCheckSerialInput,
    }): CancelablePromise<VehicleCheckSerialResponse> {
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
     * @returns VehicleMinimal successful
     * @throws ApiError
     */
    public postVehicles({
        requestBody,
    }: {
        requestBody: VehicleCreateInput,
    }): CancelablePromise<VehicleMinimal> {
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
     * @deprecated
     * Vehicles List -> use GET /hangar
     * @returns Hangar successful
     * @throws ApiError
     */
    public getVehicles({
        page,
        perPage,
        q,
    }: {
        page?: number,
        perPage?: string,
        q?: HangarQuery,
    }): CancelablePromise<Hangar> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
            },
        });
    }

    /**
     * @deprecated
     * Vehicle Fleetchart List -> use GET /hangar
     * @returns VehicleMinimal successful
     * @throws ApiError
     */
    public fleetchart(): CancelablePromise<Array<VehicleMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/fleetchart',
        });
    }

    /**
     * @deprecated
     * Vehicle Export -> use GET /hangar/export
     * @returns VehicleExport successful
     * @throws ApiError
     */
    public export(): CancelablePromise<Array<VehicleExport>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/export',
        });
    }

    /**
     * @deprecated
     * Vehicle import -> use PUT /hangar/import
     * @returns HangarImportResult successful
     * @throws ApiError
     */
    public import({
        formData,
    }: {
        formData: string,
    }): CancelablePromise<HangarImportResult> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/vehicles/import',
            formData: formData,
            mediaType: 'multipart/form-data',
        });
    }

    /**
     * @deprecated
     * Vehicle Destroy all -> use DELETE /hangar
     * @returns void
     * @throws ApiError
     */
    public destroyAll(): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/vehicles/destroy-all',
        });
    }

    /**
     * @deprecated
     * Vehicle embed -> use GET /public/hangar/embed
     * @returns VehicleMinimal successful
     * @throws ApiError
     */
    public embed(): CancelablePromise<Array<VehicleMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/embed',
        });
    }

    /**
     * @deprecated
     * Vehicle Hangar items -> use GET /hangar/items
     * @returns string successful
     * @throws ApiError
     */
    public hangarItems(): CancelablePromise<Array<string>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/hangar-items',
        });
    }

    /**
     * @deprecated
     * Vehicle hangar -> no replacement
     * @returns VehicleMinimal successful
     * @throws ApiError
     */
    public hangar(): CancelablePromise<Array<VehicleMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/hangar',
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
     * @returns VehicleMinimal successful
     * @throws ApiError
     */
    public destroy({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<VehicleMinimal> {
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
     * @returns VehicleMinimal successful
     * @throws ApiError
     */
    public update({
        id,
        requestBody,
    }: {
        /**
         * id
         */
        id: string,
        requestBody: VehicleUpdateInput,
    }): CancelablePromise<VehicleMinimal> {
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

}
