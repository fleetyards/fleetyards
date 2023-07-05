/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * create fleet
     * @returns any successful
     * @throws ApiError
     */
    public postFleets(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets',
        });
    }

    /**
     * show fleet
     * @returns any successful
     * @throws ApiError
     */
    public getFleets({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * update fleet
     * @returns any successful
     * @throws ApiError
     */
    public patchFleets({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/fleets/{slug}',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * update fleet
     * @returns any successful
     * @throws ApiError
     */
    public putFleets({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/fleets/{slug}',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * delete fleet
     * @returns any successful
     * @throws ApiError
     */
    public deleteFleets({
        slug,
    }: {
        /**
         * slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{slug}',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * check fleet
     * @returns any successful
     * @throws ApiError
     */
    public postFleetsCheck(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/check',
        });
    }

    /**
     * invites fleet
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsInvites(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/invites',
        });
    }

    /**
     * current fleet
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsCurrent(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/current',
        });
    }

}
