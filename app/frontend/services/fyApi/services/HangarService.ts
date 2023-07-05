/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarSyncResult } from '../models/HangarSyncResult';
import type { SyncRsiHangarInput } from '../models/SyncRsiHangarInput';
import type { VehicleMinimal } from '../models/VehicleMinimal';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class HangarService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Clear your personal hangar
     * @returns void
     * @throws ApiError
     */
    public deleteHangar(): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/hangar',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Your personal hangar
     * @returns VehicleMinimal successful
     * @throws ApiError
     */
    public getHangar({
        page,
        perPage,
    }: {
        page?: number,
        perPage?: string,
    }): CancelablePromise<Array<VehicleMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar',
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Import to your personal hangar
     * @returns any successful
     * @throws ApiError
     */
    public putHangarImport({
        formData,
    }: {
        formData: string,
    }): CancelablePromise<any> {
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
     * Move all Ingame Ships from your Hangar to your Wishlist
     * @returns void
     * @throws ApiError
     */
    public putHangarMoveAllIngameToWishlist(): CancelablePromise<void> {
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
    public putHangarSyncRsiHangar({
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
