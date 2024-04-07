/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ModelQuery } from '../models/ModelQuery';
import type { Models } from '../models/Models';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ModelsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Models list
     * @returns Models successful
     * @throws ApiError
     */
    public models({
        page = '1',
        perPage = '30',
        s,
        q,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: ModelQuery,
    }): CancelablePromise<Models> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models',
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
