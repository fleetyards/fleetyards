/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ManufacturersService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list manufacturers
     * @returns any successful
     * @throws ApiError
     */
    public getManufacturers(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/manufacturers',
        });
    }

    /**
     * with_models manufacturer
     * @returns any successful
     * @throws ApiError
     */
    public getManufacturersWithModels(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/manufacturers/with-models',
        });
    }

}
