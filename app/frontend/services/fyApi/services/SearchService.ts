/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class SearchService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list searches
     * @returns any successful
     * @throws ApiError
     */
    public getSearch(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/search',
        });
    }

}
