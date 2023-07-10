/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarImportResult } from '../models/HangarImportResult';
import type { HangarQuery } from '../models/HangarQuery';
import type { HangarSyncResult } from '../models/HangarSyncResult';
import type { SyncRsiHangarInput } from '../models/SyncRsiHangarInput';
import type { VehicleExport } from '../models/VehicleExport';
import type { VehicleMinimal } from '../models/VehicleMinimal';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class HangarService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Clear your personal Hangar
     * @returns void
     * @throws ApiError
     */
    public destroy(): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/hangar',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Your personal Hangar
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
            url: '/hangar',
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
     * Export your personal Hangar
     * @returns VehicleExport successful
     * @throws ApiError
     */
    public export(): CancelablePromise<Array<VehicleExport>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar/export',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Import to your personal Hangar
     * @returns HangarImportResult successful
     * @throws ApiError
     */
    public import({
        formData,
    }: {
        formData: string,
    }): CancelablePromise<HangarImportResult> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar/import',
            formData: formData,
            mediaType: 'multipart/form-data',
            errors: {
                400: `bad request`,
                401: `unauthorized`,
            },
        });
    }

    /**
     * Your personal Hangar items
     * @returns string successful
     * @throws ApiError
     */
    public items(): CancelablePromise<Array<string>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar/items',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Move all Ingame Ships from your Hangar to your Wishlist
     * @returns void
     * @throws ApiError
     */
    public moveAllIngameToWishlist(): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar/move-all-ingame-to-wishlist',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Sync RSI Hangar
     * @returns HangarSyncResult successful
     * @throws ApiError
     */
    public syncRsiHangar({
        requestBody,
    }: {
        requestBody: {
            items?: SyncRsiHangarInput;
        },
    }): CancelablePromise<HangarSyncResult> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar/sync-rsi-hangar',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
                401: `unauthorized`,
            },
        });
    }

}
