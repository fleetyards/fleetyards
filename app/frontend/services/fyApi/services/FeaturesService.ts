/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class FeaturesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Feature Flags for User
     * @returns string successful
     * @throws ApiError
     */
    public features(): CancelablePromise<Array<string>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/features',
        });
    }

}
