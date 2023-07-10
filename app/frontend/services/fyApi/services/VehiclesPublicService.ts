/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { VehicleMinimalPublic } from '../models/VehicleMinimalPublic';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class VehiclesPublicService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * @deprecated
     * public vehicle
     * @returns VehicleMinimalPublic successful
     * @throws ApiError
     */
    public getVehicles({
        username,
    }: {
        /**
         * username
         */
        username: string,
    }): CancelablePromise<Array<VehicleMinimalPublic>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/{username}',
            path: {
                'username': username,
            },
        });
    }

    /**
     * @deprecated
     * public_fleetchart vehicle
     * @returns VehicleMinimalPublic successful
     * @throws ApiError
     */
    public getVehiclesFleetchart({
        username,
    }: {
        /**
         * username
         */
        username: string,
    }): CancelablePromise<Array<VehicleMinimalPublic>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/{username}/fleetchart',
            path: {
                'username': username,
            },
        });
    }

    /**
     * @deprecated
     * public_quick_stats vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesQuickStats({
        username,
    }: {
        /**
         * username
         */
        username: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/{username}/quick-stats',
            path: {
                'username': username,
            },
        });
    }

}
