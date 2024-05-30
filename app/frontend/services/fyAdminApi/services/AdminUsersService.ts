/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { AdminUser } from '../models/AdminUser';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class AdminUsersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * My Data
     * @returns AdminUser successful
     * @throws ApiError
     */
    public me(): CancelablePromise<AdminUser> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/admin_users/me',
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
