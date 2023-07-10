/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarEmbedQuery } from '../models/HangarEmbedQuery';
import type { HangarPublic } from '../models/HangarPublic';
import type { HangarQuery } from '../models/HangarQuery';
import type { VehicleMinimalPublic } from '../models/VehicleMinimalPublic';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class PublicHangarService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Public Hangar embed
     * @returns VehicleMinimalPublic empty response
     * @throws ApiError
     */
    public embed({
        usernames,
    }: {
        usernames: HangarEmbedQuery,
    }): CancelablePromise<Array<VehicleMinimalPublic>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/hangars/embed',
            query: {
                'usernames': usernames,
            },
        });
    }

    /**
     * Public Hangar
     * @returns HangarPublic successful
     * @throws ApiError
     */
    public get({
        username,
        page,
        perPage,
        q,
    }: {
        username: string,
        page?: string,
        perPage?: string,
        q?: HangarQuery,
    }): CancelablePromise<HangarPublic> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/hangars/{username}',
            path: {
                'username': username,
            },
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
            },
            errors: {
                404: `not found`,
            },
        });
    }

}
