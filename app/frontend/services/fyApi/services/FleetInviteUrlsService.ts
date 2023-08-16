/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FleetMember } from '../models/FleetMember';
import type { FleetMembershipCreateInput } from '../models/FleetMembershipCreateInput';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetInviteUrlsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

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
