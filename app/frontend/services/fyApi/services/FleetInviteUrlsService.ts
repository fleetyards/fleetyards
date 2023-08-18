/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FleetInviteUrlCreateInput } from '../models/FleetInviteUrlCreateInput';
import type { FleetInviteUrlMinimal } from '../models/FleetInviteUrlMinimal';
import type { FleetMember } from '../models/FleetMember';
import type { FleetMembershipCreateInput } from '../models/FleetMembershipCreateInput';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetInviteUrlsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Create Invite Url
     * @returns FleetInviteUrlMinimal successful
     * @throws ApiError
     */
    public createInviteUrl({
        fleetSlug,
        requestBody,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        requestBody: FleetInviteUrlCreateInput,
    }): CancelablePromise<FleetInviteUrlMinimal> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/{fleetSlug}/invite-urls',
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
     * Fleet Invite Urls List
     * @returns FleetInviteUrlMinimal successful
     * @throws ApiError
     */
    public inviteUrls({
        fleetSlug,
        page = '1',
        perPage = '30',
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        page?: string,
        perPage?: string,
    }): CancelablePromise<Array<FleetInviteUrlMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{fleetSlug}/invite-urls',
            path: {
                'fleetSlug': fleetSlug,
            },
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

    /**
     * Remove Invite Url
     * You are not the owner of this Fleet
     * @returns void
     * @throws ApiError
     */
    public removeInviteUrl({
        fleetSlug,
        token,
    }: {
        /**
         * Fleet slug
         */
        fleetSlug: string,
        /**
         * Invite Url Token
         */
        token: string,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{fleetSlug}/invite-urls/{token}',
            path: {
                'fleetSlug': fleetSlug,
                'token': token,
            },
            errors: {
                401: `unauthorized`,
                403: `forbidden`,
                404: `not found`,
            },
        });
    }

    /**
     * Create Membership by Invite
     * User is already a member of this fleet
     * @returns FleetMember successful
     * @throws ApiError
     */
    public useInvite({
        requestBody,
    }: {
        requestBody: FleetMembershipCreateInput,
    }): CancelablePromise<FleetMember> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/use-invite',
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
