/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class UsersService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * public user
     * @returns any successful
     * @throws ApiError
     */
    public getUsers({
        username,
    }: {
        /**
         * username
         */
        username: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/users/{username}',
            path: {
                'username': username,
            },
        });
    }

}
