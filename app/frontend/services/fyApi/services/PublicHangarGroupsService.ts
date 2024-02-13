/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarGroupPublic } from '../models/HangarGroupPublic';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class PublicHangarGroupsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * HangarGroup list
     * @returns HangarGroupPublic successful
     * @throws ApiError
     */
    public publicHangarGroups({
        username,
    }: {
        /**
         * Username
         */
        username: string,
    }): CancelablePromise<Array<HangarGroupPublic>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/hangars/{username}/groups',
            path: {
                'username': username,
            },
        });
    }
}
