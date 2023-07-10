/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarQuery } from '../models/HangarQuery';
import type { VehicleExport } from '../models/VehicleExport';
import type { VehicleMinimal } from '../models/VehicleMinimal';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class WishlistService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Clear your Wishlist
     * @returns void
     * @throws ApiError
     */
    public destroy(): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/wishlist',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Your Wishlist
     * @returns VehicleMinimal successful
     * @throws ApiError
     */
    public get({
        page,
        perPage,
        q,
    }: {
        page?: string,
        perPage?: string,
        q?: HangarQuery,
    }): CancelablePromise<Array<VehicleMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/wishlist',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Export your Wishlist
     * @returns VehicleExport successful
     * @throws ApiError
     */
    public export(): CancelablePromise<Array<VehicleExport>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/wishlist/export',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Your Wishlist items
     * @returns string successful
     * @throws ApiError
     */
    public items(): CancelablePromise<Array<string>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/wishlist/items',
            errors: {
                401: `unauthorized`,
            },
        });
    }

}
