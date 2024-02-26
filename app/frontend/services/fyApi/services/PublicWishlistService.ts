/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarPublic } from '../models/HangarPublic';
import type { HangarQuery } from '../models/HangarQuery';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class PublicWishlistService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Your Wishlist
     * @returns HangarPublic successful
     * @throws ApiError
     */
    public get({
        username,
        page = '1',
        perPage = '30',
        q,
    }: {
        username: string,
        page?: string,
        perPage?: string,
        q?: HangarQuery,
    }): CancelablePromise<HangarPublic> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/wishlists/{username}',
            path: {
                'username': username,
            },
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
            },
            errors: {
                404: `not found`,
            },
        });
    }
}
