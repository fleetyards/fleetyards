/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarEmbedQuery } from '../models/HangarEmbedQuery';
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
    public publicHangarEmbed({
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
     * @returns VehicleMinimalPublic successful
     * @throws ApiError
     */
    public publicHangar({
        username,
        page = '1',
        perPage = '30',
        q,
    }: {
        username: string,
        page?: string,
        perPage?: string,
        q?: HangarQuery,
    }): CancelablePromise<Array<VehicleMinimalPublic>> {
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
