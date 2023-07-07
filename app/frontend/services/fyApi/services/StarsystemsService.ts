/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { StarsystemMinimal } from '../models/StarsystemMinimal';
import type { StarsystemQuery } from '../models/StarsystemQuery';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class StarsystemsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Starsystems list
     * @returns StarsystemMinimal successful
     * @throws ApiError
     */
    public list({
        page,
        perPage,
        q,
    }: {
        page?: number,
        perPage?: string,
        q?: StarsystemQuery,
    }): CancelablePromise<Array<StarsystemMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/starsystems',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
            },
        });
    }

    /**
     * show starsystem
     * Get Detail of a Starsystem referenced by its Slug
     * @returns StarsystemMinimal successful
     * @throws ApiError
     */
    public getStarsystems({
        slug,
    }: {
        /**
         * Starsystem slug
         */
        slug: string,
    }): CancelablePromise<StarsystemMinimal> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/starsystems/{slug}',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not_found`,
            },
        });
    }

}
