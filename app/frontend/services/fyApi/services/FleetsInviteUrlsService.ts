/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FleetsInviteUrlsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list fleet_invite_urls
     * @returns any successful
     * @throws ApiError
     */
    public getFleetsInviteUrls({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/fleets/{slug}/invite-urls',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * create fleet_invite_url
     * @returns any successful
     * @throws ApiError
     */
    public postFleetsInviteUrls({
        slug,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/fleets/{slug}/invite-urls',
            path: {
                'slug': slug,
            },
        });
    }

    /**
     * delete fleet_invite_url
     * @returns any successful
     * @throws ApiError
     */
    public deleteFleetsInviteUrls({
        slug,
        token,
    }: {
        /**
         * Fleet slug
         */
        slug: string,
        /**
         * token
         */
        token: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/fleets/{slug}/invite-urls/{token}',
            path: {
                'slug': slug,
                'token': token,
            },
        });
    }

}
