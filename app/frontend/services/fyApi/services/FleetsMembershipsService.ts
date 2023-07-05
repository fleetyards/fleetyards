/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetsMembershipsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * update fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public putFleetsMembers({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}/members',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * update fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public patchFleetsMembers({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/fleets/{slug}/members',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * create fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public postFleetsMembers({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/{slug}/members',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * create_by_invite fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public postFleetsUseInvite(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/use-invite',
        });
    }

    /**
     * current fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsMembersCurrent({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/members/current',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * accept_invite fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public putFleetsMembersAcceptInvite({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}/members/accept-invite',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * decline_invite fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public putFleetsMembersDeclineInvite({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}/members/decline-invite',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * leave fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public deleteFleetsMembersLeave({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{slug}/members/leave',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * create_by_invite fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public postFleetsMembersCreateByInvite({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/{slug}/members/create-by-invite',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * demote fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public putFleetsMembersDemote({
        slug,
        username,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
        /**
         * username
         */
        username: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}/members/{username}/demote',
            path: {
                'slug': slug,
                'username': username,
            },
        });
    }

    /**
     * promote fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public putFleetsMembersPromote({
        slug,
        username,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
        /**
         * username
         */
        username: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}/members/{username}/promote',
            path: {
                'slug': slug,
                'username': username,
            },
        });
    }

    /**
     * accept_request fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public putFleetsMembersAcceptRequest({
        slug,
        username,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
        /**
         * username
         */
        username: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}/members/{username}/accept-request',
            path: {
                'slug': slug,
                'username': username,
            },
        });
    }

    /**
     * decline_request fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public putFleetsMembersDeclineRequest({
        slug,
        username,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
        /**
         * username
         */
        username: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}/members/{username}/decline-request',
            path: {
                'slug': slug,
                'username': username,
            },
        });
    }

    /**
     * delete fleet_membership
     * @returns any successful
     * @throws ApiError
     */
    public deleteFleetsMembers({
        slug,
        username,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
        /**
         * username
         */
        username: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{slug}/members/{username}',
            path: {
                'slug': slug,
                'username': username,
            },
        });
    }

}
