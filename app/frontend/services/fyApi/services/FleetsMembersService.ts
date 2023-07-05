/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetsMembersService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list fleet_members
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsMembers({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/members',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * quick_stats fleet_member
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsMemberQuickStats({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/member-quick-stats',
            path: {
                'slug': slug,
            },
        });
    }

}
