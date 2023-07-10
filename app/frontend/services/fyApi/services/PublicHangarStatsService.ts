/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarQuery } from '../models/HangarQuery';
import type { HangarStatsPublic } from '../models/HangarStatsPublic';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class PublicHangarStatsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Public Hangar Stats
     * @returns HangarStatsPublic successful
     * @throws ApiError
     */
    public publicHangarStats({
        username,
        q,
    }: {
        /**
         * username
         */
        username: string,
        q?: HangarQuery,
    }): CancelablePromise<HangarStatsPublic> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/hangars/{username}/stats',
            path: {
                'username': username,
            },
            query: {
                'q': q,
            },
            errors: {
                404: `not found`,
            },
        });
    }

}
