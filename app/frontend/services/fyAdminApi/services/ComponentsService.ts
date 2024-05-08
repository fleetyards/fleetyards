/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ComponentQuery } from '../models/ComponentQuery';
import type { Components } from '../models/Components';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ComponentsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Components list
     * @returns Components successful
     * @throws ApiError
     */
    public components({
        page = '1',
        perPage = '50',
        s,
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: ComponentQuery,
        cacheId?: string,
    }): CancelablePromise<Components> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/components',
            query: {
                'page': page,
                'perPage': perPage,
                's': s,
                'q': q,
                'cacheId': cacheId,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
