/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class PasswordsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * update password
     * @returns any successful
     * @throws ApiError
     */
    public patchPassword(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/password',
        });
    }

    /**
     * update password
     * @returns any successful
     * @throws ApiError
     */
    public putPassword(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/password',
        });
    }

    /**
     * request_email password
     * @returns any successful
     * @throws ApiError
     */
    public postPasswordRequest(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/password/request',
        });
    }

    /**
     * update password
     * @returns any successful
     * @throws ApiError
     */
    public patchPasswordUpdate(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/password/update',
        });
    }

    /**
     * update password
     * @returns any successful
     * @throws ApiError
     */
    public putPasswordUpdate(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/password/update',
        });
    }

    /**
     * update_with_token password
     * @returns any successful
     * @throws ApiError
     */
    public patchPasswordUpdate1({
        resetPasswordToken,
    }: {
        /**
         * reset_password_token
         */
        resetPasswordToken: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/password/update/{reset_password_token}',
            path: {
                'reset_password_token': resetPasswordToken,
            },
        });
    }

    /**
     * update_with_token password
     * @returns any successful
     * @throws ApiError
     */
    public putPasswordUpdate1({
        resetPasswordToken,
    }: {
        /**
         * reset_password_token
         */
        resetPasswordToken: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/password/update/{reset_password_token}',
            path: {
                'reset_password_token': resetPasswordToken,
            },
        });
    }

}
