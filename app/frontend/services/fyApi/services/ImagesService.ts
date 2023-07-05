/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Image } from '../models/Image';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ImagesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list images
     * Get a List of Images
     * @returns Image successful
     * @throws ApiError
     */
    public getImages(): CancelablePromise<Array<Image>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/images',
        });
    }

    /**
     * random image
     * Get a randomized List of Images
     * @returns Image successful
     * @throws ApiError
     */
    public getImagesRandom(): CancelablePromise<Array<Image>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/images/random',
        });
    }

}
