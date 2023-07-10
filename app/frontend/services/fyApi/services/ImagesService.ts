/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ImageComplete } from '../models/ImageComplete';
import type { ImageQuery } from '../models/ImageQuery';
import type { Images } from '../models/Images';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ImagesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Images list
     * @returns Images successful
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
        q?: ImageQuery,
        cacheId?: string,
    }): CancelablePromise<Images> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/images',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }

    /**
     * Images random list
     * Get a randomized List of 14 Images
     * @returns ImageComplete successful
     * @throws ApiError
     */
    public random({
        limit,
    }: {
        limit?: number,
    }): CancelablePromise<Array<ImageComplete>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/images/random',
            query: {
                'limit': limit,
            },
        });
    }

}
