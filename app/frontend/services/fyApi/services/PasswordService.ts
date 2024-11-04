/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { PasswordInput } from '../models/PasswordInput';
import type { PasswordRequestInput } from '../models/PasswordRequestInput';
import type { StandardMessage } from '../models/StandardMessage';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class PasswordService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Request Password reset
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public requestPasswordReset({
        requestBody,
    }: {
        requestBody: PasswordRequestInput,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/password/request',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
            },
        });
    }
    /**
     * Update password
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public updatePassword({
        requestBody,
    }: {
        requestBody: PasswordInput,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/password',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
                401: `unauthorized`,
            },
        });
    }
    /**
     * Update Password with Token
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public updatePasswordWithToken({
        token,
        requestBody,
    }: {
        token: string,
        requestBody: PasswordInput,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/password/{token}',
            path: {
                'token': token,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
            },
        });
    }
}
