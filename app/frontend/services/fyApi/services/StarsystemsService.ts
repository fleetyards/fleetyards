/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Starsystem } from '../models/Starsystem';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class StarsystemsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list starsystems
     * Get a List of Starsystems
     * @returns Starsystem successful
     * @throws ApiError
     */
    public getStarsystems(): CancelablePromise<Array<Starsystem>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/starsystems',
        });
    }

    /**
     * show starsystem
     * Get Detail of a Starsystem referenced by its Slug
     * @returns Starsystem successful
     * @throws ApiError
     */
    public getStarsystems1({
        slug,
    }: {
        /**
         * slug
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
