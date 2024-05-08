/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { UserQuery } from '../models/UserQuery';
import type { Users } from '../models/Users';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class UsersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Users list
     * @returns Users successful
     * @throws ApiError
     */
    public users({
        page = '1',
        perPage = '25',
        s,
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: UserQuery,
        cacheId?: string,
    }): CancelablePromise<Users> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/users',
            query: {
                'page': page,
                'perPage': perPage,
                's': s,
                'q': q,
                'cacheId': cacheId,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
