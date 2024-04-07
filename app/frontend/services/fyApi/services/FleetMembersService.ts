/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FleetMember } from '../models/FleetMember';
import type { FleetMemberCreateInput } from '../models/FleetMemberCreateInput';
import type { FleetMemberQuery } from '../models/FleetMemberQuery';
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
