/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { UserPublic } from '../models/UserPublic';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class PublicUserService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Public User
     * @returns UserPublic successful
     * @throws ApiError
     */
    public publicUser({
        username,
    }: {
        username: string,
    }): CancelablePromise<UserPublic> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/public/users/{username}',
            path: {
                'username': username,
            },
            errors: {
                404: `not found`,
            },
        });
    }
}
