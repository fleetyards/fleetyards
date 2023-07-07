/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { PublicHangarStats } from '../models/PublicHangarStats';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class PublicHangarStatsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Public Hangar Stats
     * @returns PublicHangarStats successful
     * @throws ApiError
     */
    public get({
        username,
    }: {
        /**
         * username
         */
        username: string,
    }): CancelablePromise<PublicHangarStats> {
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
