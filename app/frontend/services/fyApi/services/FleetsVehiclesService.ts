/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetsVehiclesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list fleet_vehicles
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsVehicles({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/vehicles',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * public fleet_vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsPublicVehicles({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/public-vehicles',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * fleetchart fleet_vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsFleetchart({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/fleetchart',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * public_fleetchart fleet_vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsPublicFleetchart({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/public-fleetchart',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * quick_stats fleet_vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsQuickStats({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/quick-stats',
            path: {
                'slug': slug,
            },
        });
    }

}
