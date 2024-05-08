/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Import } from '../models/Import';
import type { ImportQuery } from '../models/ImportQuery';
import type { Imports } from '../models/Imports';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ImportsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Imports list
     * Get a List of Imports
     * @returns Imports successful
     * @throws ApiError
     */
    public imports({
        page = '1',
        perPage = '25',
        s,
        q,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: ImportQuery,
    }): CancelablePromise<Imports> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/imports',
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
    /**
     * Import Detail
     * @returns Import successful
     * @throws ApiError
     */
    public import({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<Import> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/imports/{id}',
            path: {
                'id': id,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
}
