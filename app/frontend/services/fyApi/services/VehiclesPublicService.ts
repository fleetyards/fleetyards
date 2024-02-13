/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { VehiclePublic } from '../models/VehiclePublic';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class VehiclesPublicService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * @deprecated
     * public vehicle
     * @returns VehiclePublic successful
     * @throws ApiError
     */
    public deprecateDgetPublicVehicles({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<Array<VehiclePublic>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/{id}',
            path: {
                'id': id,
            },
        });
    }
    /**
     * @deprecated
     * public_fleetchart vehicle
     * @returns VehiclePublic successful
     * @throws ApiError
     */
    public deprecateDgetPublicFleetchart({
        id,
    }: {
        /**
         * username
         */
        id: string,
    }): CancelablePromise<Array<VehiclePublic>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/{id}/fleetchart',
            path: {
                'id': id,
            },
        });
    }
    /**
     * @deprecated
     * public_quick_stats vehicle
     * @returns any successful
     * @throws ApiError
     */
    public deprecateDgetPublicQuickStats({
        id,
    }: {
        /**
         * username
         */
        id: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/{id}/quick-stats',
            path: {
                'id': id,
            },
        });
    }
}
