/* generated using openapi-typescript-codegen -- do not edit */
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
     * Get a List of Stations
     * @returns Stations successful
     * @throws ApiError
     */
    public stations({
        page = '1',
        perPage = '10',
        s,
        q,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: StationQuery,
    }): CancelablePromise<Stations> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/stations',
            query: {
                'page': page,
                'perPage': perPage,
                's': s,
                'q': q,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
