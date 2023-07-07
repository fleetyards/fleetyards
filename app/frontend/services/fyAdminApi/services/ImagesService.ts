/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Image } from '../models/Image';
import type { ImageInputCreate } from '../models/ImageInputCreate';

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
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * create image
     * Create a new Image
     * @returns Image successful
     * @throws ApiError
     */
    public postImages({
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
     * update image
     * @returns Image successful
     * @throws ApiError
     */
    public patchImages({
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
            method: 'PATCH',
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
     * update image
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
     * delete image
     * @returns any successful
     * @throws ApiError
     */
    public deleteImages({
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
