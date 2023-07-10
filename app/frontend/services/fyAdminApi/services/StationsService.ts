/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { StationQuery } from '../models/StationQuery';
import type { Stations } from '../models/Stations';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class StationsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Stations list
     * Get a List of Images
     * @returns Stations successful
     * @throws ApiError
     */
    public stations({
        page = '1',
        perPage = '30',
        q,
    }: {
        page?: string,
        perPage?: string,
        q?: StationQuery,
    }): CancelablePromise<Stations> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }

}
