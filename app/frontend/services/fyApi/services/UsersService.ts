/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Check } from '../models/Check';
import type { CheckInput } from '../models/CheckInput';
import type { User } from '../models/User';
import type { UserCreateInput } from '../models/UserCreateInput';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class UsersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Check E-Mail Availability
     * @returns Check successful
     * @throws ApiError
     */
    public checkEmail({
        requestBody,
    }: {
        requestBody: CheckInput,
    }): CancelablePromise<Check> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/check-email',
            body: requestBody,
            mediaType: 'application/json',
        });
    }
    /**
     * Check Username Availability
     * @returns Check successful
     * @throws ApiError
     */
    public checkUsername({
        requestBody,
    }: {
        requestBody: CheckInput,
    }): CancelablePromise<Check> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/check-username',
            body: requestBody,
            mediaType: 'application/json',
        });
    }
    /**
     * Create new User
     * @returns User successful
     * @throws ApiError
     */
    public signup({
        requestBody,
    }: {
        requestBody: UserCreateInput,
    }): CancelablePromise<User> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/signup',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
                422: `unprocessable entity`,
            },
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
