/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Check } from '../models/Check';
import type { CheckInput } from '../models/CheckInput';
import type { Fleet } from '../models/Fleet';
import type { FleetCreateInput } from '../models/FleetCreateInput';
import type { FleetMember } from '../models/FleetMember';
import type { FleetModelCountsStats } from '../models/FleetModelCountsStats';
import type { FleetPublicVehicles } from '../models/FleetPublicVehicles';
import type { FleetUpdateInput } from '../models/FleetUpdateInput';
import type { FleetVehicleExport } from '../models/FleetVehicleExport';
import type { FleetVehicleQuery } from '../models/FleetVehicleQuery';
import type { FleetVehicles } from '../models/FleetVehicles';
import type { VehiclePublic } from '../models/VehiclePublic';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class FleetsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Check Fleet FID Availability
     * @returns Check successful
     * @throws ApiError
     */
    public checkFid({
        requestBody,
    }: {
        requestBody: CheckInput,
    }): CancelablePromise<Check> {
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
     * Find Fleet by Invite
     * @returns Fleet successful
     * @throws ApiError
     */
    public findByInvite({
        token,
    }: {
        /**
         * Fleet Invite Token
         */
        token: string,
    }): CancelablePromise<Fleet> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/find-by-invite/{token}',
            path: {
                'token': token,
            },
            errors: {
                401: `unauthorized`,
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
     * Fleet Vehicles List
     * @returns FleetVehicleExport successful
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
    }): CancelablePromise<Array<FleetVehicleExport>> {
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
     * @returns FleetVehicles successful
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
    }): CancelablePromise<FleetVehicles> {
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
     * @returns FleetPublicVehicles successful
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
    }): CancelablePromise<FleetPublicVehicles> {
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
