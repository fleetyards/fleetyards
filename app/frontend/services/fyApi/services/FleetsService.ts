/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Fleet } from '../models/Fleet';
import type { FleetCheck } from '../models/FleetCheck';
import type { FleetCheckInput } from '../models/FleetCheckInput';
import type { FleetCreateInput } from '../models/FleetCreateInput';
import type { FleetMember } from '../models/FleetMember';
import type { FleetModelCountsStats } from '../models/FleetModelCountsStats';
import type { FleetUpdateInput } from '../models/FleetUpdateInput';
import type { FleetVehicleQuery } from '../models/FleetVehicleQuery';
import type { FleetVehiclesStats } from '../models/FleetVehiclesStats';
import type { Model } from '../models/Model';
import type { VehicleExport } from '../models/VehicleExport';
import type { VehiclePublic } from '../models/VehiclePublic';

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
     * @deprecated
     * Fleets for current User -> use GET /fleets/my
     * @returns Fleet successful
     * @throws ApiError
     */
    public deprecateDcurrentFleets(): CancelablePromise<Array<Fleet>> {
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
     * @returns FleetMember successful
     * @throws ApiError
     */
    public fleetInvites(): CancelablePromise<Array<FleetMember>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/invites',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Fleets for current User
     * @returns Fleet successful
     * @throws ApiError
     */
    public myFleets(): CancelablePromise<Array<Fleet>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/my',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * @deprecated
     * Fleet Public Vehicles -> use GET /fleets/{fleetSlug}/public/vehicles
     * @returns any successful
     * @throws ApiError
     */
    public deprecateDfleetPublicVehicles({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<Array<(Model | VehiclePublic)>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/public-vehicles',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }

    /**
     * @deprecated
     * Fleet Fleetchart -> use GET /fleets/{fleetSlug}/vehicles
     * @returns any successful
     * @throws ApiError
     */
    public deprecateDfleetFleetchart({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/fleetchart',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }

    /**
     * @deprecated
     * Fleet Public Fleetchart -> use GET /fleets/{fleetSlug}/public/vehicles
     * @returns any successful
     * @throws ApiError
     */
    public deprecateDpublicFleetFleetchart({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/public-fleetchart',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }

    /**
     * @deprecated
     * Fleet Vehicle QuickStats -> use GET /fleets/{fleetSlug}/stats/vehicles
     * @returns FleetVehiclesStats successful
     * @throws ApiError
     */
    public deprecateDfleetVehicleQuickStats({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<FleetVehiclesStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/quick-stats',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }

    /**
     * @deprecated
     * Fleet Stats Model Counts -> use GET /fleets/{fleetSlug}/stats/model-counts
     * @returns FleetModelCountsStats successful
     * @throws ApiError
     */
    public deprecateDfleetStatsModelCounts({
        fleetSlug,
        q,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<FleetModelCountsStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/model-counts',
            path: {
                'fleetSlug': fleetSlug,
            },
            query: {
                'q': q,
            },
        });
    }

    /**
     * @deprecated
     * Public Fleet Stats Model Counts -> use GET /public/fleets/{fleetSlug}/stats/model-counts
     * @returns FleetModelCountsStats successful
     * @throws ApiError
     */
    public deprecateDpublicFleetStatsModelCounts({
        fleetSlug,
        q,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<FleetModelCountsStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/public-model-counts',
            path: {
                'fleetSlug': fleetSlug,
            },
            query: {
                'q': q,
            },
        });
    }

    /**
     * @deprecated
     * Fleet Vehicles Embed for the Fleetyards Widget -> use GET /public/fleets/{fleetSlug}/vehicles/embed
     * @returns VehiclePublic successful
     * @throws ApiError
     */
    public deprecateDfleetVehiclesEmbed({
        fleetSlug,
        q,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<Array<VehiclePublic>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/embed',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
        q,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<Array<VehicleExport>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/vehicles/export',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
        page = '1',
        perPage = '30',
        q,
        grouped,
        cacheId,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        page?: string,
        perPage?: string,
        q?: FleetVehicleQuery,
        grouped?: boolean,
        cacheId?: string,
    }): CancelablePromise<Array<(Model | VehiclePublic)>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/vehicles',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
        q,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<FleetModelCountsStats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/fleets/{fleetSlug}/stats/model-counts',
            path: {
                'fleetSlug': fleetSlug,
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
     * @returns VehiclePublic successful
     * @throws ApiError
     */
    public publicFleetVehiclesEmbed({
        fleetSlug,
        q,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        q?: FleetVehicleQuery,
    }): CancelablePromise<Array<VehiclePublic>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/fleets/{fleetSlug}/vehicles/embed',
            path: {
                'fleetSlug': fleetSlug,
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
        fleetSlug,
        page = '1',
        perPage = '30',
        q,
        grouped,
        cacheId,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        page?: string,
        perPage?: string,
        q?: FleetVehicleQuery,
        grouped?: boolean,
        cacheId?: string,
    }): CancelablePromise<Array<(Model | VehiclePublic)>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/fleets/{fleetSlug}/vehicles',
            path: {
                'fleetSlug': fleetSlug,
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
