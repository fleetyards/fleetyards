/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Starsystem } from '../models/Starsystem';
import type { StarsystemQuery } from '../models/StarsystemQuery';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class StarsystemsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Starsystems list
     * @returns Starsystem successful
     * @throws ApiError
     */
    public starsystems({
        page = '1',
        perPage = '15',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: StarsystemQuery,
        cacheId?: string,
    }): CancelablePromise<Array<Starsystem>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/starsystems',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }
    /**
     * Starsystem Detail
     * @returns Starsystem successful
     * @throws ApiError
     */
    public starsystem({
        slug,
    }: {
        /**
         * Starsystem slug
         */
        slug: string,
    }): CancelablePromise<Starsystem> {
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
