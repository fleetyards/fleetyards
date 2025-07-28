/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Image } from '../models/Image';
import type { ImageQuery } from '../models/ImageQuery';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ImagesService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Images list
     * @returns Image successful
     * @throws ApiError
     */
    public images({
        page = '1',
        perPage = '30',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: ImageQuery,
        cacheId?: string,
    }): CancelablePromise<Array<Image>> {
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
     * @returns Image successful
     * @throws ApiError
     */
    public imagesRandom({
        limit = 14,
    }: {
        limit?: number,
    }): CancelablePromise<Array<Image>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/images/random',
            query: {
                'limit': limit,
            },
        });
    }
}
