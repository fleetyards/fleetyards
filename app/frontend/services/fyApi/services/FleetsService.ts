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
import type { FleetUpdateInput } from '../models/FleetUpdateInput';

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

}
