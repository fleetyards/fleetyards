/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { User } from '../models/User';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class UsersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * @deprecated
     * My Data
     * @returns User successful
     * @throws ApiError
     */
    public deprecateDcurrent(): CancelablePromise<User> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/users/current',
        });
    }
    /**
     * My Data
     * @returns User successful
     * @throws ApiError
     */
    public me(): CancelablePromise<User> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/users/me',
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
