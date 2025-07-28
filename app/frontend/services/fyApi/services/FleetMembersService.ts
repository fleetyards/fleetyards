/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FleetMember } from '../models/FleetMember';
import type { FleetMemberCreateInput } from '../models/FleetMemberCreateInput';
import type { FleetMemberQuery } from '../models/FleetMemberQuery';
import type { FleetMembershipUpdateInput } from '../models/FleetMembershipUpdateInput';
import type { StandardMessage } from '../models/StandardMessage';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class FleetMembersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Accept Member
     * No Member found
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public acceptMember({
        fleetSlug,
        username,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        /**
         * Username
         */
        username: string,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/members/{username}/accept',
            path: {
                'fleetSlug': fleetSlug,
                'username': username,
            },
            errors: {
                400: `bad request`,
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }
    /**
     * Create Member
     * You are not the owner of this Fleet
     * @returns FleetMember successful
     * @throws ApiError
     */
    public createMember({
        fleetSlug,
        requestBody,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        requestBody: FleetMemberCreateInput,
    }): CancelablePromise<FleetMember> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/{fleetSlug}/members',
            path: {
                'fleetSlug': fleetSlug,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }
    /**
     * @deprecated
     * Update Membership -> use PUT /fleets/{fleetSlug}/membership
     * @returns FleetMember successful
     * @throws ApiError
     */
    public deprecateDupdateMembership({
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
            url: '/fleets/{fleetSlug}/members',
            path: {
                'fleetSlug': fleetSlug,
            },
            body: requestBody,
            mediaType: 'application/json',
        });
    }
    /**
     * Fleet Member List
     * @returns FleetMember successful
     * @throws ApiError
     */
    public fleetMembers({
        fleetSlug,
        page = '1',
        perPage = '30',
        q,
        cacheId,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        page?: string,
        perPage?: string,
        q?: FleetMemberQuery,
        cacheId?: string,
    }): CancelablePromise<Array<FleetMember>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/members',
            path: {
                'fleetSlug': fleetSlug,
            },
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
    /**
     * Decline Member
     * No Member found
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public declineMember({
        fleetSlug,
        username,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        /**
         * Username
         */
        username: string,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/members/{username}/decline',
            path: {
                'fleetSlug': fleetSlug,
                'username': username,
            },
            errors: {
                400: `bad request`,
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }
    /**
     * Demote Member
     * No Member found
     * @returns FleetMember successful
     * @throws ApiError
     */
    public demoteMember({
        fleetSlug,
        username,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        /**
         * Username
         */
        username: string,
    }): CancelablePromise<FleetMember> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/members/{username}/demote',
            path: {
                'fleetSlug': fleetSlug,
                'username': username,
            },
            errors: {
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }
    /**
     * @deprecated
     * My Fleet Membership -> use GET /fleets/{fleetSlug}/membership
     * @returns FleetMember successful
     * @throws ApiError
     */
    public deprecateDfleetMembership({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<FleetMember> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/members/current',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }
    /**
     * @deprecated
     * Accept Member -> use GET /fleets/{fleetSlug}/members/{username}/accept
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public deprecateDacceptMember({
        fleetSlug,
        username,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        /**
         * Username
         */
        username: string,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/members/{username}/accept-request',
            path: {
                'fleetSlug': fleetSlug,
                'username': username,
            },
        });
    }
    /**
     * @deprecated
     * Decline Member -> use GET /fleets/{fleetSlug}/members/{username}/decline
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public deprecateDdeclineMember({
        fleetSlug,
        username,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        /**
         * Username
         */
        username: string,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/members/{username}/decline-request',
            path: {
                'fleetSlug': fleetSlug,
                'username': username,
            },
        });
    }
    /**
     * @deprecated
     * Accept Membership -> use GET /fleets/{fleetSlug}/membership/accept
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public deprecateDacceptMembership({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/members/accept-invite',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }
    /**
     * @deprecated
     * Decline Membership -> use GET /fleets/{fleetSlug}/membership/decline
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public deprecateDdeclineMembership({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/members/decline-invite',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }
    /**
     * @deprecated
     * Leave Fleet -> use DELETE /fleets/{fleetSlug}/membership
     * @returns void
     * @throws ApiError
     */
    public deprecateDleaveFleet({
        fleetSlug,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{fleetSlug}/members/leave',
            path: {
                'fleetSlug': fleetSlug,
            },
        });
    }
    /**
     * Remove Fleet Member
     * You are not the owner of this Fleet
     * @returns void
     * @throws ApiError
     */
    public removeMember({
        fleetSlug,
        username,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        /**
         * username
         */
        username: string,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{fleetSlug}/members/{username}',
            path: {
                'fleetSlug': fleetSlug,
                'username': username,
            },
            errors: {
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }
    /**
     * Promote Member
     * No Member found
     * @returns FleetMember successful
     * @throws ApiError
     */
    public promoteMember({
        fleetSlug,
        username,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        /**
         * Username
         */
        username: string,
    }): CancelablePromise<FleetMember> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{fleetSlug}/members/{username}/promote',
            path: {
                'fleetSlug': fleetSlug,
                'username': username,
            },
            errors: {
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }
}
