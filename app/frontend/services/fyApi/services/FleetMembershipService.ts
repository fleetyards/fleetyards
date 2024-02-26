/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FleetMember } from '../models/FleetMember';
import type { FleetMembershipUpdateInput } from '../models/FleetMembershipUpdateInput';
import type { StandardMessage } from '../models/StandardMessage';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class FleetMembershipService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Accept Membership
     * No Membership found
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public acceptMembership({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/membership/accept',
            path: {
                'fleetSlug': fleetSlug,
            },
            errors: {
                400: `bad request`,
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
    /**
     * Decline Membership
     * No Membership found
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public declineMembership({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/membership/decline',
            path: {
                'fleetSlug': fleetSlug,
            },
            errors: {
                400: `bad request`,
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
    /**
     * Leave Fleet
     * @returns void
     * @throws ApiError
     */
    public leaveFleet({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{fleetSlug}/membership',
            path: {
                'fleetSlug': fleetSlug,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
    /**
     * Fleet Membership Detail
     * Membership for this slug and user does not exist
     * @returns FleetMember successful
     * @throws ApiError
     */
    public membership({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<FleetMember> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/membership',
            path: {
                'fleetSlug': fleetSlug,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
    /**
     * Update Membership
     * Fleet for this slug and user does not exist
     * @returns FleetMember successful
     * @throws ApiError
     */
    public updateMembership({
        fleetSlug,
        requestBody,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        requestBody: FleetMembershipUpdateInput,
    }): CancelablePromise<FleetMember> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/membership',
            path: {
                'fleetSlug': fleetSlug,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
}
