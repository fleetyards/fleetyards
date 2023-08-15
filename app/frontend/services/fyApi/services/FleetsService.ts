/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Fleet } from '../models/Fleet';
import type { FleetCheck } from '../models/FleetCheck';
import type { FleetCheckInput } from '../models/FleetCheckInput';
import type { FleetCreateInput } from '../models/FleetCreateInput';
import type { FleetMembership } from '../models/FleetMembership';
import type { FleetMinimal } from '../models/FleetMinimal';
import type { FleetModelCountsStats } from '../models/FleetModelCountsStats';
import type { FleetUpdateInput } from '../models/FleetUpdateInput';
import type { FleetVehicleQuery } from '../models/FleetVehicleQuery';
import type { ModelMinimal } from '../models/ModelMinimal';
import type { VehicleExport } from '../models/VehicleExport';
import type { VehiclePublicMinimal } from '../models/VehiclePublicMinimal';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Check Fleet FID Availability
     * @returns FleetCheck successful
     * @throws ApiError
     */
    public checkFid({
        requestBody,
    }: {
        requestBody: FleetCheckInput,
    }): CancelablePromise<FleetCheck> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/check',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Create Fleet
     * @returns Fleet successful
     * @throws ApiError
     */
    public createFleet({
        requestBody,
    }: {
        requestBody: FleetCreateInput,
    }): CancelablePromise<Fleet> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
                401: `unauthorized`,
            },
        });
    }

    /**
     * Fleets for current User
     * @returns FleetMinimal successful
     * @throws ApiError
     */
    public currentFleet(): CancelablePromise<Array<FleetMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/current',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Destroy Fleet
     * You are not the owner of this Fleet
     * @returns void
     * @throws ApiError
     */
    public removeFleet({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{slug}',
            path: {
                'slug': slug,
            },
            errors: {
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }

    /**
     * Fleet Detail
     * @returns Fleet successful
     * @throws ApiError
     */
    public fleet({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<Fleet> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Update Fleet
     * You are not an Admin or Officer of this Fleet
     * @returns Fleet successful
     * @throws ApiError
     */
    public updateFleet({
        slug,
        formData,
    }: {
        /**
         * slug
         */
        slug: string,
        formData: FleetUpdateInput,
    }): CancelablePromise<Fleet> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}',
            path: {
                'slug': slug,
            },
            formData: formData,
            mediaType: 'multipart/form-data',
            errors: {
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }

    /**
     * Fleet Invites current User
     * @returns FleetMembership successful
     * @throws ApiError
     */
    public fleetInvites(): CancelablePromise<Array<FleetMembership>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/invites',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * @deprecated
     * Fleet Public Vehicles -> use GET /fleets/{slug}/public/vehicles
     * @returns any successful
     * @throws ApiError
     */
    public deprecateDfleetPublicVehicles({
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
     * @deprecated
     * Fleet Fleetchart -> use GET /fleets/{slug}/vehicles
     * @returns any successful
     * @throws ApiError
     */
    public deprecateDfleetFleetchart({
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
     * @deprecated
     * Fleet Public Fleetchart -> use GET /fleets/{slug}/public/vehicles
     * @returns any successful
     * @throws ApiError
     */
    public deprecateDpublicFleetchart({
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
     * @deprecated
     * Fleet Vehicle QuickStats -> use GET /fleets/{slug}/stats/vehicles
     * @returns any successful
     * @throws ApiError
     */
    public deprecateDpublicFleetchart1({
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

    /**
     * @deprecated
     * Fleet Stats Model Counts -> use GET /fleets/{slug}/stats/model-counts
     * @returns FleetModelCountsStats successful
     * @throws ApiError
     */
    public deprecateDfleetStatsModelCounts({
        slug,
        q,
    }: {
        /**
         * slug
         */
        slug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<FleetModelCountsStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/model-counts',
            path: {
                'slug': slug,
            },
            query: {
                'q': q,
            },
        });
    }

    /**
     * @deprecated
     * Public Fleet Stats Model Counts -> use GET /public/fleets/{slug}/stats/model-counts
     * @returns FleetModelCountsStats successful
     * @throws ApiError
     */
    public deprecateDpublicFleetStatsModelCounts({
        slug,
        q,
    }: {
        /**
         * slug
         */
        slug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<FleetModelCountsStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/public-model-counts',
            path: {
                'slug': slug,
            },
            query: {
                'q': q,
            },
        });
    }

    /**
     * @deprecated
     * Fleet Vehicles Embed for the Fleetyards Widget -> use GET /public/fleets/{slug}/vehicles/embed
     * @returns VehiclePublicMinimal successful
     * @throws ApiError
     */
    public deprecateDfleetVehiclesEmbed({
        slug,
        q,
    }: {
        /**
         * slug
         */
        slug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<Array<VehiclePublicMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/embed',
            path: {
                'slug': slug,
            },
            query: {
                'q': q,
            },
        });
    }

    /**
     * Fleet Vehicles List
     * @returns VehicleExport successful
     * @throws ApiError
     */
    public fleetVehiclesExport({
        slug,
        q,
    }: {
        /**
         * slug
         */
        slug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<Array<VehicleExport>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/vehicles/export',
            path: {
                'slug': slug,
            },
            query: {
                'q': q,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

    /**
     * Fleet Vehicles List
     * @returns any successful
     * @throws ApiError
     */
    public fleetVehicles({
        slug,
        page = '1',
        perPage = '30',
        q,
        grouped,
        cacheId,
    }: {
        /**
         * slug
         */
        slug: string,
        page?: string,
        perPage?: string,
        q?: FleetVehicleQuery,
        grouped?: boolean,
        cacheId?: string,
    }): CancelablePromise<Array<(ModelMinimal | VehiclePublicMinimal)>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/vehicles',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'grouped': grouped,
                'cacheId': cacheId,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

    /**
     * Public Fleet Stats Model Counts
     * @returns FleetModelCountsStats successful
     * @throws ApiError
     */
    public publicFleetStatsModelCounts({
        slug,
        q,
    }: {
        /**
         * slug
         */
        slug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<FleetModelCountsStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/fleets/{slug}/stats/model-counts',
            path: {
                'slug': slug,
            },
            query: {
                'q': q,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Public Fleet Vehicles Embed for the Fleetyards Widget
     * @returns VehiclePublicMinimal successful
     * @throws ApiError
     */
    public publicFleetVehiclesEmbed({
        slug,
        q,
    }: {
        /**
         * slug
         */
        slug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<Array<VehiclePublicMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/fleets/{slug}/vehicles/embed',
            path: {
                'slug': slug,
            },
            query: {
                'q': q,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Public Fleet Vehicles List
     * @returns any successful
     * @throws ApiError
     */
    public publicFleetVehicles({
        slug,
        page = '1',
        perPage = '30',
        q,
        grouped,
        cacheId,
    }: {
        /**
         * slug
         */
        slug: string,
        page?: string,
        perPage?: string,
        q?: FleetVehicleQuery,
        grouped?: boolean,
        cacheId?: string,
    }): CancelablePromise<Array<(ModelMinimal | VehiclePublicMinimal)>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/fleets/{slug}/vehicles',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'grouped': grouped,
                'cacheId': cacheId,
            },
            errors: {
                404: `not found`,
            },
        });
    }

}
