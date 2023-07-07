/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { PublicHangarQuickstats } from '../models/PublicHangarQuickstats';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class PublicHangarStatsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Public Hangar Quickstats
     * @returns PublicHangarQuickstats successful
     * @throws ApiError
     */
    public get({
        username,
    }: {
        /**
         * username
         */
        username: string,
    }): CancelablePromise<PublicHangarQuickstats> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/hangars/{username}/stats',
            path: {
                'username': username,
            },
            errors: {
                404: `not found`,
            },
        });
    }

}
