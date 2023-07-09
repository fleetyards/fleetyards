/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Image } from '../models/Image';
import type { ImageInputCreate } from '../models/ImageInputCreate';
import type { ImageQuery } from '../models/ImageQuery';
import type { Images } from '../models/Images';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ImagesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Images list
     * Get a List of Images
     * @returns Images successful
     * @throws ApiError
     */
    public list({
        page,
        perPage,
        q,
    }: {
        page?: number,
        perPage?: string,
        q?: ImageQuery,
    }): CancelablePromise<Images> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/images',
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
     * Image create
     * Create a new Image
     * @returns Image successful
     * @throws ApiError
     */
    public create({
        formData,
    }: {
        formData?: ImageInputCreate,
    }): CancelablePromise<Image> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/images',
            formData: formData,
            mediaType: 'multipart/form-data',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * Image update
     * @returns Image successful
     * @throws ApiError
     */
    public putImages({
        id,
        requestBody,
    }: {
        /**
         * id
         */
        id: string,
        requestBody?: {
            $ref?: any;
        },
    }): CancelablePromise<Image> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/images/{id}',
            path: {
                'id': id,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
                404: `not_found`,
            },
        });
    }

    /**
     * Image destroy
     * @returns any successful
     * @throws ApiError
     */
    public destroy({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/images/{id}',
            path: {
                'id': id,
            },
            errors: {
                401: `unauthorized`,
                404: `not_found`,
            },
        });
    }

}
