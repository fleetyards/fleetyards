/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { SearchQuery } from '../models/SearchQuery';
import type { SearchResult } from '../models/SearchResult';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class SearchService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list searches
     * @returns SearchResult successful
     * @throws ApiError
     */
    public search({
        q,
    }: {
        q?: SearchQuery,
    }): CancelablePromise<Array<SearchResult>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/search',
            query: {
                'q': q,
            },
        });
    }

}
