/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CelestialObjectMinimal } from '../models/CelestialObjectMinimal';
import type { CelestialObjectQuery } from '../models/CelestialObjectQuery';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class CelestialObjectsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Celestial Objects List
     * Get a List of Celestial Objects
     * @returns CelestialObjectMinimal successful
     * @throws ApiError
     */
    public list({
        page,
        perPage,
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: CelestialObjectQuery,
        cacheId?: string,
    }): CancelablePromise<Array<CelestialObjectMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/celestial-objects',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }

    /**
     * Celestial Object Detail
     * Get Detail of a Celestial Object referenced by its Slug
     * @returns CelestialObjectMinimal successful
     * @throws ApiError
     */
    public get({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<CelestialObjectMinimal> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/celestial-objects/{slug}',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not_found`,
            },
        });
    }

}
