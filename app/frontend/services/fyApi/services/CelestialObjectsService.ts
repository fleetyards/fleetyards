/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CelestialObject } from '../models/CelestialObject';
import type { CelestialObjectQuery } from '../models/CelestialObjectQuery';
import type { CelestialObjects } from '../models/CelestialObjects';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class CelestialObjectsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Celestial Objects List
     * Get a List of Celestial Objects
     * @returns CelestialObjects successful
     * @throws ApiError
     */
    public list({
        page = '1',
        perPage = '30',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: CelestialObjectQuery,
        cacheId?: string,
    }): CancelablePromise<CelestialObjects> {
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
     * @returns CelestialObject successful
     * @throws ApiError
     */
    public detail({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<CelestialObject> {
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
